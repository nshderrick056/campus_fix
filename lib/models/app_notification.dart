import 'package:equatable/equatable.dart';

import 'incident_status.dart';

/// An in-app alert about a status change on one of the user's reports
/// (`users/{uid}/notifications/{id}`).
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.incidentId,
    required this.incidentTitle,
    required this.status,
    required this.createdAt,
    required this.read,
    this.note,
  });

  final String id;
  final String incidentId;
  final String incidentTitle;

  /// The status the incident moved to.
  final IncidentStatus status;
  final DateTime createdAt;
  final bool read;
  final String? note;

  @override
  List<Object?> get props =>
      [id, incidentId, incidentTitle, status, createdAt, read, note];
}
