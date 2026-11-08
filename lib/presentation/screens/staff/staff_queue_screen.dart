import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/form_status.dart';
import '../../../logic/incidents/incidents_cubit.dart';
import '../../../models/incident_status.dart';
import '../../widgets/common.dart';
import '../../widgets/report_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../reports/reports_screen.dart';

/// Staff home: workload counts and the reports that need attention,
/// oldest first. Has its own [IncidentsCubit] (defaulting to "Submitted")
/// so its filters don't affect the All Reports tab.
class StaffQueueScreen extends StatelessWidget {
  const StaffQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidentsCubit(context.read<IncidentRepository>(), sort: IncidentSort.oldest)
        ..filterStatus(IncidentStatus.submitted),
      child: const _QueueView(),
    );
  }
}

class _QueueView extends StatelessWidget {
  const _QueueView();

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit a) => a.state.user)!;
    final state = context.watch<IncidentsCubit>().state;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final newCount = state.countWhere(IncidentStatus.submitted);
    final items = state.visible(user.uid);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Symbols.badge_rounded, size: 16, color: c.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('Staff · ${user.department ?? 'Campus staff'}',
                          style: t.labelMedium?.copyWith(color: c.primary), overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  Text('Hello, ${user.displayName.split(' ').first}',
                      style: t.headlineMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const ThemeToggleButton(),
              UserAvatar(initials: user.initials),
            ]),
            const SizedBox(height: 8),
            Text(
              newCount == 0
                  ? 'No new reports waiting. Nice work.'
                  : '$newCount new report${newCount == 1 ? ' is' : 's are'} waiting for review. Oldest first keeps response times fair.',
              style: t.bodyLarge?.copyWith(color: c.textMuted),
            ),
            const SizedBox(height: 16),
            Row(children: [
              _kpi(IncidentStatus.submitted, '$newCount', 'New', c.submitted, c.submittedBg),
              const SizedBox(width: 8),
              _kpi(IncidentStatus.inProgress, '${state.countWhere(IncidentStatus.inProgress)}', 'In Progress', c.inProgress, c.inProgressBg),
              const SizedBox(width: 8),
              _kpi(IncidentStatus.resolved, '${state.countWhere(IncidentStatus.resolved)}', 'Resolved', c.resolved, c.resolvedBg),
              const SizedBox(width: 8),
              Expanded(
                child: StatCard(
                    icon: Symbols.description_rounded, value: '${state.all.length}', label: 'All time', foreground: c.primary, background: c.iceSoft),
              ),
            ]),
            const SizedBox(height: 16),
            const IncidentFilters(),
            const SizedBox(height: 12),
            SectionHeader(
              'Needs attention',
              action: state.sort == IncidentSort.oldest ? 'Oldest first' : 'Newest first',
              onAction: context.read<IncidentsCubit>().toggleSort,
            ),
            if (state.status == LoadStatus.loading) const LoadingView(),
            if (state.status == LoadStatus.failure)
              MessageView.error(message: state.error ?? 'Could not load reports.', onAction: context.read<IncidentsCubit>().retry),
            if (state.status == LoadStatus.loaded && items.isEmpty)
              const MessageView(
                icon: Symbols.task_alt_rounded,
                title: 'All clear',
                message: 'No reports match these filters.',
              ),
            for (final i in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ReportCard(incident: i, onTap: () => context.push(Routes.incident(i.id))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(IncidentStatus s, String value, String label, Color fg, Color bg) =>
      Expanded(child: StatCard(icon: s.icon, value: value, label: label, foreground: fg, background: bg));
}
