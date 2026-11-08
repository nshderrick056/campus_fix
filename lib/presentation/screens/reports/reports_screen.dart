import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/form_status.dart';
import '../../../logic/incidents/incidents_cubit.dart';
import '../../../models/incident_category.dart';
import '../../../models/incident_status.dart';
import '../../widgets/common.dart';
import '../../widgets/report_card.dart';

/// Browse, search and filter reports. Students can switch between all
/// reports and their own; staff see everything.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, this.staffView = false});

  final bool staffView;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(staffView ? 'All Reports' : 'Campus Reports',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    if (!staffView) ...[const _ScopeToggle(), const SizedBox(height: 12)],
                    const IncidentFilters(),
                  ],
                ),
              ),
            ),
            const _ResultsList(),
          ],
        ),
      ),
    );
  }
}

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle();

  @override
  Widget build(BuildContext context) {
    final scope = context.select((IncidentsCubit c) => c.state.scope);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<IncidentScope>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: IncidentScope.all, label: Text('All reports')),
          ButtonSegment(value: IncidentScope.mine, label: Text('My reports')),
        ],
        selected: {scope},
        onSelectionChanged: (s) => context.read<IncidentsCubit>().setScope(s.first),
      ),
    );
  }
}

/// Search box, status chips, category filter and sort. Reused by the staff queue.
class IncidentFilters extends StatefulWidget {
  const IncidentFilters({super.key});

  @override
  State<IncidentFilters> createState() => _IncidentFiltersState();
}

class _IncidentFiltersState extends State<IncidentFilters> {
  late final _search = TextEditingController(text: context.read<IncidentsCubit>().state.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final cubit = context.read<IncidentsCubit>();
    final current = cubit.state.categoryFilter;
    final picked = await showModalBottomSheet<IncidentCategory?>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          ListTile(
            leading: const Icon(Symbols.select_all_rounded),
            title: const Text('All categories'),
            trailing: current == null ? const Icon(Symbols.check_rounded) : null,
            onTap: () => Navigator.pop(ctx, null),
          ),
          for (final cat in IncidentCategory.values)
            ListTile(
              leading: Icon(cat.icon),
              title: Text(cat.label),
              trailing: current == cat ? const Icon(Symbols.check_rounded) : null,
              onTap: () => Navigator.pop(ctx, cat),
            ),
        ]),
      ),
    );
    if (!mounted) return;
    cubit.filterCategory(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<IncidentsCubit>().state;
    final cubit = context.read<IncidentsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          onChanged: cubit.search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search by title or location',
            prefixIcon: const Icon(Symbols.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Filter by category',
              onPressed: _pickCategory,
              icon: Badge(
                isLabelVisible: state.categoryFilter != null,
                smallSize: 8,
                backgroundColor: c.primary,
                child: Icon(Symbols.tune_rounded, color: c.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip(context, 'All', state.statusFilter == null, () => cubit.filterStatus(null)),
            for (final s in IncidentStatus.values)
              _chip(context, s.label, state.statusFilter == s, () => cubit.filterStatus(s)),
          ]),
        ),
        if (state.categoryFilter != null) ...[
          const SizedBox(height: 8),
          InputChip(
            avatar: Icon(state.categoryFilter!.icon, size: 18),
            label: Text(state.categoryFilter!.label),
            onDeleted: () => cubit.filterCategory(null),
            deleteButtonTooltipMessage: 'Clear category filter',
          ),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        backgroundColor: c.card,
        side: selected ? BorderSide.none : BorderSide(color: c.border),
        labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(color: selected ? c.onPrimary : c.textMuted),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncidentsCubit>().state;
    final uid = context.select((AuthCubit a) => a.state.user?.uid) ?? '';
    if (state.status == LoadStatus.loading) {
      return const SliverFillRemaining(hasScrollBody: false, child: LoadingView());
    }
    if (state.status == LoadStatus.failure) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: MessageView.error(message: state.error ?? 'Could not load reports.', onAction: context.read<IncidentsCubit>().retry),
      );
    }
    final items = state.visible(uid);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList.list(children: [
        _ResultsBar(count: items.length),
        const SizedBox(height: 8),
        if (items.isEmpty)
          MessageView(
            icon: Symbols.search_off_rounded,
            title: state.hasFilters ? 'No matching reports' : 'No reports yet',
            message: state.hasFilters ? 'Try a different search or clear the filters.' : 'Reports from campus will appear here.',
            actionLabel: state.hasFilters ? 'Clear filters' : null,
            onAction: state.hasFilters ? context.read<IncidentsCubit>().clearFilters : null,
          ),
        for (final i in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ReportCard(incident: i, onTap: () => context.push(Routes.incident(i.id))),
          ),
      ]),
    );
  }
}

class _ResultsBar extends StatelessWidget {
  const _ResultsBar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final sort = context.select((IncidentsCubit c) => c.state.sort);
    return Row(children: [
      Expanded(child: Text('$count report${count == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodySmall)),
      TextButton.icon(
        onPressed: context.read<IncidentsCubit>().toggleSort,
        icon: const Icon(Symbols.swap_vert_rounded, size: 18),
        label: Text(sort == IncidentSort.newest ? 'Newest first' : 'Oldest first'),
      ),
    ]);
  }
}
