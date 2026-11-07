import 'repositories/auth_repository.dart';
import 'repositories/incident_repository.dart';
import 'repositories/notification_repository.dart';

/// Everything the app needs from the data layer. `main.dart` builds one of
/// these (Firebase in the real app, in-memory fakes for UI work and tests)
/// and provides the repositories to the widget tree.
class Backend {
  const Backend({
    required this.auth,
    required this.incidents,
    required this.notifications,
  });

  final AuthRepository auth;
  final IncidentRepository incidents;
  final NotificationRepository notifications;
}
