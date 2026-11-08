import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../logic/form_status.dart';
import '../../../logic/notifications/notifications_cubit.dart';
import '../../../models/app_notification.dart';
import '../../../models/incident_status.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';

/// Status-change alerts on the student's own reports.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NotificationsCubit>().state;
    final t = Theme.of(context).textTheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final todayItems = state.items.where((n) => !n.createdAt.isBefore(today)).toList();
    final earlier = state.items.where((n) => n.createdAt.isBefore(today)).toList();
    return Scaffold(
      body: SafeArea(
        child: switch (state.status) {
          LoadStatus.loading => const LoadingView(),
          LoadStatus.failure when state.items.isEmpty =>
            const MessageView.error(message: 'Could not load your notifications.'),
          _ => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Row(children: [
                  Expanded(child: Text('Notifications', style: t.titleLarge)),
                  if (state.unread > 0)
                    TextButton.icon(
                      onPressed: context.read<NotificationsCubit>().markAllRead,
                      icon: const Icon(Symbols.done_all_rounded, size: 18),
                      label: const Text('Mark all read'),
                    ),
                ]),
                const SizedBox(height: 8),
                if (state.items.isEmpty)
                  const MessageView(
                    icon: Symbols.notifications_off_rounded,
                    title: 'No notifications',
                    message: 'You will be notified here when staff update one of your reports.',
                  ),
                if (todayItems.isNotEmpty) ...[const _GroupLabel('TODAY'), for (final n in todayItems) _AlertTile(n)],
                if (earlier.isNotEmpty) ...[const _GroupLabel('EARLIER'), for (final n in earlier) _AlertTile(n)],
              ],
            ),
        },
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1)),
      );
}

class _AlertTile extends StatelessWidget {
  const _AlertTile(this.n);

  final AppNotification n;

  String get _title => switch (n.status) {
        IncidentStatus.submitted => 'Report received',
        IncidentStatus.inProgress => 'Report in progress',
        IncidentStatus.resolved => 'Report resolved',
        IncidentStatus.rejected => 'Report closed',
      };

  String get _message => switch (n.status) {
        IncidentStatus.submitted => '“${n.incidentTitle}” is awaiting review.',
        IncidentStatus.inProgress => 'Staff started working on “${n.incidentTitle}”.',
        IncidentStatus.resolved => '“${n.incidentTitle}” was marked as resolved.',
        IncidentStatus.rejected => '“${n.incidentTitle}” was closed as a duplicate or invalid report.',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final (fg, bg) = statusColors(context, n.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: n.read ? c.surface : c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: n.read ? c.border : Colors.transparent),
        ),
        elevation: n.read ? 0 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<NotificationsCubit>().markRead(n.id);
            context.push(Routes.incident(n.incidentId));
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 20, backgroundColor: bg, child: Icon(n.status.icon, color: fg, size: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(_title, style: t.labelLarge)),
                    Text(relativeTime(n.createdAt), style: t.bodySmall),
                    if (!n.read) ...[
                      const SizedBox(width: 6),
                      Semantics(label: 'Unread', child: CircleAvatar(radius: 4, backgroundColor: c.primary)),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(_message, style: t.bodyMedium?.copyWith(color: c.textMuted)),
                  if (n.note != null) ...[
                    const SizedBox(height: 4),
                    Text('Note: ${n.note}', style: t.bodySmall?.copyWith(color: c.navy)),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
