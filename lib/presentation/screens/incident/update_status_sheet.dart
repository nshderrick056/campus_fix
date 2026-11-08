import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/incidents/incident_detail_cubit.dart';
import '../../../models/incident.dart';
import '../../../models/incident_status.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';

const _descriptions = {
  IncidentStatus.submitted: 'Awaiting review',
  IncidentStatus.inProgress: 'Work has started',
  IncidentStatus.resolved: 'Issue has been fixed',
  IncidentStatus.rejected: 'Duplicate or invalid report',
};

/// Staff-only sheet for moving an incident to a new status with an optional
/// note to the reporter.
Future<void> showUpdateStatusSheet(BuildContext context, Incident incident) {
  final cubit = context.read<IncidentDetailCubit>();
  final staff = context.read<AuthCubit>().state.user!;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _UpdateStatusSheet(
      incident: incident,
      onSubmit: (status, note) => cubit.updateStatus(status, staff: staff, note: note),
    ),
  );
}

class _UpdateStatusSheet extends StatefulWidget {
  const _UpdateStatusSheet({required this.incident, required this.onSubmit});

  final Incident incident;
  final Future<void> Function(IncidentStatus, String?) onSubmit;

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  late IncidentStatus _selected = widget.incident.status;
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSubmit(_selected, _note.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final unchanged = _selected == widget.incident.status;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update status', style: t.titleLarge),
            const SizedBox(height: 4),
            Text('${widget.incident.title} · ${widget.incident.location}', style: t.bodyMedium?.copyWith(color: c.textMuted)),
            const SizedBox(height: 16),
            RadioGroup<IncidentStatus>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v!),
              child: Column(children: [
                for (final s in IncidentStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: _selected == s ? c.iceSoft : c.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _selected == s ? c.primary : c.border, width: _selected == s ? 2 : 1),
                      ),
                      child: RadioListTile<IncidentStatus>(
                        value: s,
                        controlAffinity: ListTileControlAffinity.trailing,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        title: Row(children: [
                          StatusChip(s),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_descriptions[s]!, style: t.bodySmall)),
                        ]),
                      ),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note to reporter (optional)',
                hintText: 'e.g. Plumber assigned, expected fix by 4 PM',
                alignLabelWithHint: true,
              ),
            ),
            const InfoBanner(
              icon: Symbols.history_rounded,
              message: 'The reporter is notified and this change is saved to the status history.',
            ),
            const SizedBox(height: 16),
            LoadingButton(
              label: unchanged ? 'Choose a new status' : 'Update status',
              icon: Symbols.check_rounded,
              loading: _saving,
              onPressed: unchanged ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
