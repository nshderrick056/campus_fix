import 'package:equatable/equatable.dart';

import 'incident_category.dart';
import 'incident_status.dart';
import 'status_change.dart';

/// An incident report (`incidents/{id}`).
class Incident extends Equatable {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.photoPublicId,
    this.statusHistory = const [],
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;

  /// When true, other students see "Anonymous"; staff still see the name.
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;
  final String? photoPublicId;

  /// Oldest first. The first entry is always the `submitted` change.
  final List<StatusChange> statusHistory;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// The reporter name as [viewerId] is allowed to see it.
  String reporterNameFor({required String viewerId, required bool viewerIsStaff}) {
    if (!isAnonymous || viewerIsStaff || viewerId == reporterId) {
      return reporterName;
    }
    return 'Anonymous';
  }

  /// Students may edit/delete their own report only while it is submitted.
  bool canBeEditedBy(String uid) =>
      uid == reporterId && status.isEditableByReporter;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        location,
        status,
        reporterId,
        reporterName,
        isAnonymous,
        createdAt,
        updatedAt,
        photoUrl,
        photoPublicId,
        statusHistory,
      ];
}
