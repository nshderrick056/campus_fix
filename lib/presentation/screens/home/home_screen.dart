import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/form_status.dart';
import '../../../logic/incidents/my_reports_cubit.dart';
import '../../../logic/notifications/notifications_cubit.dart';
import '../../../models/incident_status.dart';
import '../../widgets/common.dart';
import '../../widgets/report_card.dart';

/// Student dashboard: greeting, report CTA, summary counts, recent reports.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user)!;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final firstName = user.displayName.split(' ').first;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${greeting()},', style: t.bodyMedium?.copyWith(color: c.textMuted)),
                      Row(children: [
                        Flexible(child: Text(firstName, style: t.headlineMedium, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Icon(Symbols.waving_hand_rounded, color: c.sky, size: 26),
                      ]),
                    ],
                  ),
                ),
                const _BellButton(),
                const SizedBox(width: 10),
                UserAvatar(initials: user.initials),
              ],
            ),
            const SizedBox(height: 8),
            Text('Help make our campus safer. Report issues and follow them until they are fixed.',
                style: t.bodyLarge?.copyWith(color: c.textMuted)),
            const SizedBox(height: 20),
            const _HeroBanner(),
            const SizedBox(height: 24),
            SectionHeader('Report Summary', action: 'See all', onAction: () => context.go(Routes.reports)),
            const SizedBox(height: 8),
            const _Summary(),
            const SizedBox(height: 24),
            SectionHeader('Recent Reports', action: 'See all', onAction: () => context.go(Routes.reports)),
            const SizedBox(height: 8),
            const _Recent(),
          ],
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context) {
    final unread = context.select((NotificationsCubit n) => n.state.unread);
    final c = context.colors;
    return IconButton.filled(
      tooltip: unread > 0 ? 'Alerts, $unread unread' : 'Alerts',
      style: IconButton.styleFrom(backgroundColor: c.card, foregroundColor: c.navy),
      onPressed: () => context.go(Routes.alerts),
      icon: Badge(isLabelVisible: unread > 0, smallSize: 9, backgroundColor: c.error, child: const Icon(Symbols.notifications_rounded)),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF1B365D), Color(0xFF005A9C)]),
        boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -50, child: CircleAvatar(radius: 85, backgroundColor: c.sky.withValues(alpha: 0.22))),
          Positioned(right: 18, top: 18, child: Icon(Symbols.apartment_rounded, size: 84, color: const Color(0xFFA0E0EF).withValues(alpha: 0.55))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 210,
                  child: Text('See an issue on campus?', style: t.titleLarge?.copyWith(color: c.onHero)),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 230,
                  child: Text('Report it in under a minute and help improve our learning environment.',
                      style: t.bodyMedium?.copyWith(color: c.onHero.withValues(alpha: 0.85))),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push(Routes.newReport),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(children: [
                        Icon(Symbols.add_circle_rounded, color: Color(0xFF005A9C), size: 26),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text('Report an Issue',
                              style: TextStyle(color: Color(0xFF005A9C), fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        Icon(Symbols.chevron_right_rounded, color: Color(0xFF005A9C)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyReportsCubit>().state;
    final c = context.colors;
    Widget tile(IconData icon, int value, String label, Color fg, Color bg) => Expanded(
          child: StatCard(icon: icon, value: '$value', label: label, foreground: fg, background: bg),
        );
    return Row(children: [
      tile(Symbols.description_rounded, state.total, 'My Reports', c.primary, c.iceSoft),
      const SizedBox(width: 8),
      tile(IncidentStatus.inProgress.icon, state.count(IncidentStatus.inProgress), 'In Progress', c.inProgress, c.inProgressBg),
      const SizedBox(width: 8),
      tile(IncidentStatus.resolved.icon, state.count(IncidentStatus.resolved), 'Resolved', c.resolved, c.resolvedBg),
      const SizedBox(width: 8),
      tile(IncidentStatus.submitted.icon, state.count(IncidentStatus.submitted), 'Submitted', c.submitted, c.submittedBg),
    ]);
  }
}

class _Recent extends StatelessWidget {
  const _Recent();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MyReportsCubit>().state;
    if (state.status == LoadStatus.loading) return const LoadingView();
    if (state.status == LoadStatus.failure && state.items.isEmpty) {
      return MessageView.error(message: state.error ?? 'Could not load your reports.');
    }
    if (state.items.isEmpty) {
      return MessageView(
        icon: Symbols.inventory_2_rounded,
        title: 'No reports yet',
        message: 'When you report an issue it will appear here so you can track it.',
        actionLabel: 'Report an issue',
        onAction: () => context.push(Routes.newReport),
      );
    }
    return Column(
      children: [
        for (final i in state.items.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ReportCard(incident: i, onTap: () => context.push(Routes.incident(i.id))),
          ),
      ],
    );
  }
}
