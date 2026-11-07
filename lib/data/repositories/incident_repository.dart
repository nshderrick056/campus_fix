import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../models/incident_draft.dart';
import '../../models/incident_status.dart';

/// Incident CRUD. Streams are live (Firestore snapshots), newest first.
/// All methods throw [RepositoryException] on failure.
abstract interface class IncidentRepository {
  /// Every incident (all students can browse; staff work from this list).
  Stream<List<Incident>> watchAll();

  /// Incidents reported by [uid].
  Stream<List<Incident>> watchByReporter(String uid);

  /// One incident; emits null if it is deleted.
  Stream<Incident?> watchOne(String id);

  /// Uploads the draft's photo (if any), creates the incident with status
  /// `submitted` and a first `statusHistory` entry. Returns the new id.
  Future<String> create(IncidentDraft draft, {required AppUser reporter});

  /// Reporter only, while the incident is still `submitted`.
  Future<void> update(String id, IncidentDraft draft);

  /// Reporter only, while the incident is still `submitted`.
  Future<void> delete(String id);

  /// Staff only. Appends to `statusHistory` and writes a notification for
  /// the reporter.
  Future<void> updateStatus(
    String id, {
    required IncidentStatus status,
    required AppUser staff,
    String? note,
  });
}
