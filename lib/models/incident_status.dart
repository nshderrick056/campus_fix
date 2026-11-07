import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Lifecycle of an incident. [value] is what is stored in Firestore.
enum IncidentStatus {
  submitted('submitted', 'Submitted', Symbols.send_rounded),
  inProgress('in_progress', 'In Progress', Symbols.progress_activity_rounded),
  resolved('resolved', 'Resolved', Symbols.check_circle_rounded),
  rejected('rejected', 'Rejected', Symbols.cancel_rounded);

  const IncidentStatus(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  /// Students may edit or delete their report only while it is submitted.
  bool get isEditableByReporter => this == IncidentStatus.submitted;

  static IncidentStatus fromValue(String value) => IncidentStatus.values
      .firstWhere((s) => s.value == value, orElse: () => submitted);
}
