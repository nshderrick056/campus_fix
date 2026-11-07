import '../../models/app_notification.dart';

/// In-app alerts for status changes on the user's own reports.
abstract interface class NotificationRepository {
  /// Newest first.
  Stream<List<AppNotification>> watchFor(String uid);

  Future<void> markRead(String uid, String notificationId);

  Future<void> markAllRead(String uid);
}
