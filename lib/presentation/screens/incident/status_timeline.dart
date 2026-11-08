import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../models/incident.dart';
import '../../../models/incident_status.dart';
import '../../../models/status_change.dart';
import '../../widgets/status_chip.dart';

/// Vertical timeline of an incident's status changes. When the report is
/// still open, a final "Resolved — pending" step shows what comes next.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final history = incident.statusHistory;
    final closed = incident.status == IncidentStatus.resolved || incident.status == IncidentStatus.rejected;
    final steps = <_Step>[
      for (var i = 0; i < history.length; i++)
        _Step(change: history[i], current: i == history.length - 1 && !closed),
      if (!closed) const _Step(pending: IncidentStatus.resolved),
    ];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++) _StepRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _Step {
  const _Step({this.change, this.current = false, this.pending});

  final StatusChange? change;
  final bool current;
  final IncidentStatus? pending;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.isLast});

  final _Step step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final change = step.change;
    final status = change?.status ?? step.pending!;
    final (fg, _) = statusColors(context, status);
    final pending = change == null;

    final Widget dot = pending
        ? Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.border, width: 2), color: c.card),
          )
        : Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fg,
              boxShadow: step.current ? [BoxShadow(color: c.sky.withValues(alpha: 0.6), spreadRadius: 4)] : null,
            ),
            child: Icon(step.current ? status.icon : Symbols.check_rounded, size: 16, color: c.onPrimary),
          );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            dot,
            if (!isLast) Expanded(child: Container(width: 2, color: pending ? c.border : fg)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(status.label, style: t.labelLarge?.copyWith(color: pending ? c.textMuted : c.navy)),
                const SizedBox(height: 2),
                Text(
                  pending ? 'Pending' : '${shortDateTime(change.at)} · ${change.changedByName}',
                  style: t.bodySmall,
                ),
                if (change?.note != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: c.iceSoft, borderRadius: BorderRadius.circular(10)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Symbols.sticky_note_2_rounded, size: 16, color: c.primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(change!.note!, style: t.bodySmall?.copyWith(color: c.navy))),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
