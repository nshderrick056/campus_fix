import 'package:equatable/equatable.dart';

import 'incident_status.dart';

/// One entry in an incident's `statusHistory` (the status timeline).
class StatusChange extends Equatable {
  const StatusChange({
    required this.status,
    required this.changedBy,
    required this.changedByName,
    required this.at,
    this.note,
  });

  final IncidentStatus status;

  /// uid of the user who made the change (the reporter for `submitted`).
  final String changedBy;
  final String changedByName;
  final DateTime at;

  /// Optional note from staff to the reporter.
  final String? note;

  @override
  List<Object?> get props => [status, changedBy, changedByName, at, note];
}
