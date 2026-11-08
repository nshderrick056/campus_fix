import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../models/app_notification.dart';
import '../repositories/notification_repository.dart';
import 'firebase_errors.dart';
import 'firestore_mappers.dart';

/// [NotificationRepository] backed by `users/{uid}/notifications`.
/// Staff write these in [FirestoreIncidentRepository.updateStatus].
class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Json> _of(String uid) => _db
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection('notifications');

  @override
  Stream<List<AppNotification>> watchFor(String uid) => _of(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(notificationFromDoc).toList())
      .handleError((Object e) => throw mapFirebaseError(e));

  @override
  Future<void> markRead(String uid, String notificationId) =>
      guard(() => _of(uid).doc(notificationId).update({'read': true}));

  @override
  Future<void> markAllRead(String uid) => guard(() async {
        final unread = await _of(uid).where('read', isEqualTo: false).get();
        if (unread.docs.isEmpty) return;
        final batch = _db.batch();
        for (final doc in unread.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      });
}
