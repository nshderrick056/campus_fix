import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_constants.dart';
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
import '../../widgets/theme_toggle_button.dart';

/// Student dashboard: greeting, report CTA, summary counts, recent reports.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _HomeHeader(),
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

/// Greeting card: campus photo under a navy→blue tint, white text and icons.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user)!;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final onHero = c.onHero;
    final radius = BorderRadius.circular(24);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        image: const DecorationImage(
          image: AssetImage(AppConstants.campusPhoto),
          fit: BoxFit.cover,
          alignment: Alignment(0, 0.45),
        ),
        boxShadow: [BoxShadow(color: c.deep.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      // Tint over the photo so white text stays readable in both themes.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1B365D).withValues(alpha: 0.92), const Color(0xFF005A9C).withValues(alpha: 0.72)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
          child: IconTheme(
          data: IconThemeData(color: onHero),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${greeting()},', style: t.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.8))),
                  Row(children: [
                    Flexible(
                      child: Text(user.displayName.split(' ').first,
                          style: t.headlineMedium?.copyWith(color: onHero), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Icon(Symbols.waving_hand_rounded, color: c.sky, size: 26),
                  ]),
                ]),
              ),
              const ThemeToggleButton(),
              const _BellButton(),
              const SizedBox(width: 10),
              UserAvatar(initials: user.initials),
            ]),
            const SizedBox(height: 10),
            Text('Help make our campus safer. Report issues and follow them until they are fixed.',
                style: t.bodyMedium?.copyWith(color: onHero.withValues(alpha: 0.85))),
          ]),
          ),
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
      style: IconButton.styleFrom(backgroundColor: c.onHero.withValues(alpha: 0.16), foregroundColor: c.onHero),
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
    // Light tinted card (theme tokens), so it doesn't repeat the photo header.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.iceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.ice.withValues(alpha: 0.6)),
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: -50, child: CircleAvatar(radius: 85, backgroundColor: c.sky.withValues(alpha: 0.18))),
          Positioned(right: 18, top: 18, child: Icon(Symbols.apartment_rounded, size: 84, color: c.primary.withValues(alpha: 0.18))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 210, child: Text('See an issue on campus?', style: t.titleLarge)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 230,
                  child: Text('Report it in under a minute and help improve our learning environment.',
                      style: t.bodyMedium?.copyWith(color: c.textMuted)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push(Routes.newReport),
                    icon: const Icon(Symbols.add_circle_rounded),
                    label: const Text('Report an Issue'),
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
