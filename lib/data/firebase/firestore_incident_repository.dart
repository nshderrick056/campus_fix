import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_draft.dart';
import '../../models/incident_status.dart';
import '../../models/status_change.dart';
import '../../models/uploaded_photo.dart';
import '../repositories/incident_repository.dart';
import '../repositories/repository_exception.dart';
import '../services/photo_storage_service.dart';
import 'firebase_errors.dart';
import 'firestore_mappers.dart';

/// [IncidentRepository] backed by Cloud Firestore (`incidents/{id}`), with
/// photos stored through [PhotoStorageService].
///
/// The checks here mirror firestore.rules so users get a friendly message;
/// the rules are what actually enforce them.
class FirestoreIncidentRepository implements IncidentRepository {
  FirestoreIncidentRepository({
    required FirebaseFirestore firestore,
    required this._photos,
    DateTime Function()? clock,
  })  : _db = firestore,
        _now = clock ?? DateTime.now;

  final FirebaseFirestore _db;
  final PhotoStorageService _photos;
  final DateTime Function() _now;

  CollectionReference<Json> get _incidents =>
      _db.collection(AppConstants.incidentsCollection);

  CollectionReference<Json> _notificationsOf(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection('notifications');

  Stream<List<Incident>> _list(Query<Json> query) => query
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(incidentFromDoc).toList())
      .handleError((Object e) => throw mapFirebaseError(e));

  @override
  Stream<List<Incident>> watchAll() => _list(_incidents);

  /// Needs the composite index in firestore.indexes.json.
  @override
  Stream<List<Incident>> watchByReporter(String uid) =>
      _list(_incidents.where('reporterId', isEqualTo: uid));

  @override
  Stream<Incident?> watchOne(String id) => _incidents
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? incidentFromDoc(d) : null)
      .handleError((Object e) => throw mapFirebaseError(e));

  Future<UploadedPhoto> _upload(IncidentDraft draft) async {
    try {
      return await _photos.uploadPhoto(draft.photo!);
    } on PhotoUploadException catch (e) {
      throw RepositoryException('upload-failed', e.message);
    }
  }

  @override
  Future<String> create(IncidentDraft draft, {required AppUser reporter}) =>
      guard(() async {
        final doc = _incidents.doc();
        // Upload first so a failed upload never leaves a half-made report.
        final photo = draft.photo == null ? null : await _upload(draft);
        await doc.set(newIncidentToMap(
          draft: draft,
          reporter: reporter,
          now: _now(),
          photoUrl: photo?.url,
          photoPublicId: photo?.publicId,
        ));
        return doc.id;
      });

  Future<Incident> _require(String id) async {
    final snap = await _incidents.doc(id).get();
    if (!snap.exists) {
      throw const RepositoryException(
          'not-found', 'This report no longer exists.');
    }
    return incidentFromDoc(snap);
  }

  @override
  Future<void> update(String id, IncidentDraft draft) => guard(() async {
        final old = await _require(id);
        if (!old.status.isEditableByReporter) {
          throw const RepositoryException('locked',
              'Reports cannot be edited once staff start working on them.');
        }
        final photo = draft.photo == null ? null : await _upload(draft);
        await _incidents.doc(id).update({
          ...draftFieldsToMap(draft),
          if (photo != null) ...{
            'photoUrl': photo.url,
            'photoPublicId': photo.publicId,
          } else if (draft.removePhoto) ...{
            'photoUrl': FieldValue.delete(),
            'photoPublicId': FieldValue.delete(),
          },
          'updatedAt': timestampFrom(_now()),
        });
      });

  @override
  Future<void> delete(String id) => guard(() async {
        final old = await _require(id);
        if (!old.status.isEditableByReporter) {
          throw const RepositoryException('locked',
              'Reports cannot be deleted once staff start working on them.');
        }
        // The Cloudinary asset stays (deleting needs a signed request; see
        // PLAN.md "future work").
        await _incidents.doc(id).delete();
      });

  @override
  Future<void> updateStatus(
    String id, {
    required IncidentStatus status,
    required AppUser staff,
    String? note,
  }) =>
      guard(() async {
        if (!staff.isStaff) {
          throw const RepositoryException(
              'permission-denied', 'Only staff can update a report status.');
        }
        final cleanNote =
            (note == null || note.trim().isEmpty) ? null : note.trim();
        final ref = _incidents.doc(id);

        await _db.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) {
            throw const RepositoryException(
                'not-found', 'This report no longer exists.');
          }
          final incident = incidentFromDoc(snap);
          final now = _now();
          final change = StatusChange(
            status: status,
            changedBy: staff.uid,
            changedByName: staff.displayName,
            at: now,
            note: cleanNote,
          );
          tx.update(ref, {
            'status': status.value,
            'statusHistory': FieldValue.arrayUnion([statusChangeToMap(change)]),
            'updatedAt': timestampFrom(now),
          });
          tx.set(
            _notificationsOf(incident.reporterId).doc(),
            notificationToMap(
              incidentId: id,
              incidentTitle: incident.title,
              status: status,
              now: now,
              note: cleanNote,
            ),
          );
        });
      });
}
