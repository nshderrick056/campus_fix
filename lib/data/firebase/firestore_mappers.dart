import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/app_notification.dart';
import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_category.dart';
import '../../models/incident_draft.dart';
import '../../models/incident_status.dart';
import '../../models/status_change.dart';

/// Converts between Firestore documents and the app's models.
/// Layout: users/{uid}, users/{uid}/notifications/{id}, incidents/{id}.

typedef Json = Map<String, dynamic>;

/// Firestore [Timestamp] to [DateTime] (falls back to now if missing).
DateTime dateFrom(Object? value) => switch (value) {
      Timestamp t => t.toDate(),
      DateTime d => d,
      _ => DateTime.now(),
    };

DateTime? optionalDateFrom(Object? value) =>
    value == null ? null : dateFrom(value);

Timestamp timestampFrom(DateTime value) => Timestamp.fromDate(value);

String? _nonEmpty(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

// --- statusHistory --------------------------------------------------------

Json statusChangeToMap(StatusChange change) => {
      'status': change.status.value,
      'changedBy': change.changedBy,
      'changedByName': change.changedByName,
      if (change.note != null) 'note': change.note,
      'at': timestampFrom(change.at),
    };

StatusChange statusChangeFromMap(Json map) => StatusChange(
      status: IncidentStatus.fromValue(map['status'] as String? ?? ''),
      changedBy: map['changedBy'] as String? ?? '',
      changedByName: map['changedByName'] as String? ?? '',
      note: _nonEmpty(map['note']),
      at: dateFrom(map['at']),
    );

// --- incidents/{id} -------------------------------------------------------

Incident incidentFromMap(String id, Json map) {
  final history = (map['statusHistory'] as List<dynamic>? ?? const [])
      .whereType<Map<dynamic, dynamic>>()
      .map((e) => statusChangeFromMap(Map<String, dynamic>.from(e)))
      .toList()
    ..sort((a, b) => a.at.compareTo(b.at));

  return Incident(
    id: id,
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
    category: IncidentCategory.fromValue(map['category'] as String? ?? ''),
    location: map['location'] as String? ?? '',
    status: IncidentStatus.fromValue(map['status'] as String? ?? ''),
    reporterId: map['reporterId'] as String? ?? '',
    reporterName: map['reporterName'] as String? ?? '',
    isAnonymous: map['isAnonymous'] as bool? ?? false,
    createdAt: dateFrom(map['createdAt']),
    updatedAt: dateFrom(map['updatedAt'] ?? map['createdAt']),
    photoUrl: _nonEmpty(map['photoUrl']),
    photoPublicId: _nonEmpty(map['photoPublicId']),
    statusHistory: history,
  );
}

Incident incidentFromDoc(DocumentSnapshot<Json> doc) =>
    incidentFromMap(doc.id, doc.data() ?? const {});

/// Fields of a new incident document.
Json newIncidentToMap({
  required IncidentDraft draft,
  required AppUser reporter,
  required DateTime now,
  String? photoUrl,
  String? photoPublicId,
}) {
  final first = StatusChange(
    status: IncidentStatus.submitted,
    changedBy: reporter.uid,
    changedByName: reporter.displayName,
    at: now,
  );
  return {
    ...draftFieldsToMap(draft),
    'photoUrl': ?photoUrl,
    'photoPublicId': ?photoPublicId,
    'status': IncidentStatus.submitted.value,
    'reporterId': reporter.uid,
    'reporterName': reporter.displayName,
    'createdAt': timestampFrom(now),
    'updatedAt': timestampFrom(now),
    'statusHistory': [statusChangeToMap(first)],
  };
}

/// The fields a reporter may edit (see firestore.rules).
Json draftFieldsToMap(IncidentDraft draft) => {
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'category': draft.category.value,
      'location': draft.location.trim(),
      'isAnonymous': draft.isAnonymous,
    };

// --- users/{uid} ----------------------------------------------------------

Json newUserProfileToMap({
  required String name,
  required String email,
  required DateTime now,
}) =>
    {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'role': UserRole.student.value,
      'createdAt': timestampFrom(now),
    };

/// Combines the auth account with the profile doc ([profile] may be null
/// right after registration, before the doc exists).
AppUser appUserFrom({
  required String uid,
  required String email,
  required bool emailVerified,
  String? authDisplayName,
  Json? profile,
}) =>
    AppUser(
      uid: uid,
      email: (profile?['email'] as String?) ?? email,
      displayName: _nonEmpty(profile?['name']) ??
          _nonEmpty(authDisplayName) ??
          email.split('@').first,
      role: UserRole.fromValue(profile?['role'] as String?),
      emailVerified: emailVerified,
      department: _nonEmpty(profile?['department']),
      createdAt: optionalDateFrom(profile?['createdAt']),
    );

// --- users/{uid}/notifications/{id} ---------------------------------------

Json notificationToMap({
  required String incidentId,
  required String incidentTitle,
  required IncidentStatus status,
  required DateTime now,
  String? note,
}) =>
    {
      'incidentId': incidentId,
      'incidentTitle': incidentTitle,
      'status': status.value,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'createdAt': timestampFrom(now),
      'read': false,
    };

AppNotification notificationFromMap(String id, Json map) => AppNotification(
      id: id,
      incidentId: map['incidentId'] as String? ?? '',
      incidentTitle: map['incidentTitle'] as String? ?? '',
      status: IncidentStatus.fromValue(map['status'] as String? ?? ''),
      createdAt: dateFrom(map['createdAt']),
      read: map['read'] as bool? ?? false,
      note: _nonEmpty(map['note']),
    );

AppNotification notificationFromDoc(DocumentSnapshot<Json> doc) =>
    notificationFromMap(doc.id, doc.data() ?? const {});
