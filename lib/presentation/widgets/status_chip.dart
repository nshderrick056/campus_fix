import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/incident_status.dart';

/// Foreground/background colours for a status, from the current palette.
(Color fg, Color bg) statusColors(BuildContext context, IncidentStatus status) {
  final c = context.colors;
  return switch (status) {
    IncidentStatus.submitted => (c.submitted, c.submittedBg),
    IncidentStatus.inProgress => (c.inProgress, c.inProgressBg),
    IncidentStatus.resolved => (c.resolved, c.resolvedBg),
    IncidentStatus.rejected => (c.error, c.errorBg),
  };
}

/// Pill showing a status with icon + label (never colour alone).
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = statusColors(context, status);
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(status.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
