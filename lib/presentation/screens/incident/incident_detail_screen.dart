import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/form_status.dart';
import '../../../logic/incidents/incident_detail_cubit.dart';
import '../../../models/incident.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_photo.dart';
import '../../widgets/status_chip.dart';
import 'status_timeline.dart';
import 'update_status_sheet.dart';

class IncidentDetailScreen extends StatelessWidget {
  const IncidentDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncidentDetailCubit(context.read<IncidentRepository>(), incidentId),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Symbols.delete_rounded),
        title: const Text('Delete this report?'),
        content: const Text('It will be removed for everyone. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.colors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<IncidentDetailCubit>().delete();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth.user!;
    return BlocConsumer<IncidentDetailCubit, IncidentDetailState>(
      listenWhen: (a, b) => a.action != b.action || a.deleted != b.deleted,
      listener: (context, state) {
        if (state.action == FormStatus.failure && state.actionMessage != null) {
          showAppSnack(context, state.actionMessage!, error: true);
        } else if (state.action == FormStatus.success && state.actionMessage != null) {
          showAppSnack(context, state.actionMessage!);
        }
        if (state.deleted && context.canPop()) context.pop();
      },
      builder: (context, state) {
        final incident = state.incident;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Symbols.arrow_back_rounded),
              onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            title: const Text('Incident Details'),
            actions: [
              if (incident != null && incident.canBeEditedBy(user.uid))
                PopupMenuButton<String>(
                  tooltip: 'More',
                  icon: const Icon(Symbols.more_vert_rounded),
                  onSelected: (v) => v == 'edit'
                      ? context.push(Routes.editIncident(incident.id))
                      : _confirmDelete(context),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Symbols.edit_rounded), title: Text('Edit'))),
                    PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Symbols.delete_rounded), title: Text('Delete'))),
                  ],
                ),
            ],
          ),
          body: switch (state.status) {
            LoadStatus.loading => const LoadingView(),
            LoadStatus.failure => MessageView(
                icon: Symbols.search_off_rounded,
                title: state.deleted ? 'Report removed' : 'Report not found',
                message: 'This report no longer exists or you do not have access to it.',
              ),
            LoadStatus.loaded => _Body(incident: incident!, viewerId: user.uid, viewerIsStaff: user.isStaff),
          },
          bottomNavigationBar: incident != null && user.isStaff
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: LoadingButton(
                      label: 'Update status',
                      icon: Symbols.edit_note_rounded,
                      loading: state.action == FormStatus.submitting,
                      onPressed: () => showUpdateStatusSheet(context, incident),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.incident, required this.viewerId, required this.viewerIsStaff});

  final Incident incident;
  final String viewerId;
  final bool viewerIsStaff;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final reporter = incident.reporterNameFor(viewerId: viewerId, viewerIsStaff: viewerIsStaff);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (incident.hasPhoto) ...[
          IncidentPhoto(url: incident.photoUrl, fallbackIcon: incident.category.icon, height: 200, radius: 16, expandable: true),
          const SizedBox(height: 16),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(incident.title, style: t.titleLarge)),
          const SizedBox(width: 10),
          Padding(padding: const EdgeInsets.only(top: 4), child: StatusChip(incident.status)),
        ]),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _MetaRow(icon: incident.category.icon, label: 'Category', value: incident.category.label),
              _MetaRow(icon: Symbols.location_on_rounded, label: 'Location', value: incident.location),
              _MetaRow(icon: Symbols.calendar_today_rounded, label: 'Submitted', value: fullDateTime(incident.createdAt)),
              _MetaRow(
                icon: incident.isAnonymous ? Symbols.visibility_off_rounded : Symbols.person_rounded,
                label: 'Reported by',
                value: incident.isAnonymous && reporter != 'Anonymous' ? '$reporter (anonymous to students)' : reporter,
                last: true,
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Status timeline', style: t.titleMedium),
              const SizedBox(height: 14),
              StatusTimeline(incident: incident),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Description', style: t.titleMedium),
              const SizedBox(height: 8),
              Text(incident.description, style: t.bodyMedium),
            ]),
          ),
        ),
        if (incident.reporterId == viewerId && !incident.status.isEditableByReporter) ...[
          const SizedBox(height: 16),
          InfoBanner(
            icon: Symbols.lock_rounded,
            warning: true,
            message: 'Editing is locked once staff start working on a report. You will be notified of every status change.',
          ),
        ],
        if (!viewerIsStaff && incident.reporterId != viewerId)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('Only the reporter and campus staff can change this report.',
                style: t.bodySmall?.copyWith(color: c.textMuted), textAlign: TextAlign.center),
          ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.value, this.last = false});

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: c.primary),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: Text(label, style: t.bodySmall)),
        Expanded(child: Text(value, style: t.bodyMedium)),
      ]),
    );
  }
}
