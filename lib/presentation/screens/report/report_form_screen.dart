import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/form_status.dart';
import '../../../logic/incidents/report_form_cubit.dart';
import '../../../models/incident.dart';
import '../../../models/incident_category.dart';
import '../../widgets/common.dart';
import '../../widgets/incident_photo.dart';

/// Create a report, or edit one when [editId] is given (only while it is
/// still submitted).
class ReportFormScreen extends StatelessWidget {
  const ReportFormScreen({super.key, this.editId});

  final String? editId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<IncidentRepository>();
    final user = context.read<AuthCubit>().state.user!;
    if (editId == null) {
      return BlocProvider(
        create: (_) => ReportFormCubit(repo, reporter: user),
        child: const _ReportFormView(),
      );
    }
    // Load the report once, then build the form pre-filled.
    return StreamBuilder<Incident?>(
      stream: repo.watchOne(editId!).take(1),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done && !snap.hasData) {
          return const Scaffold(body: LoadingView());
        }
        final incident = snap.data;
        if (incident == null || !incident.canBeEditedBy(user.uid)) {
          return Scaffold(
            appBar: AppBar(),
            body: const MessageView(
              icon: Symbols.lock_rounded,
              title: 'Cannot edit this report',
              message: 'Reports can only be edited by their reporter while they are still submitted.',
            ),
          );
        }
        return BlocProvider(
          create: (_) => ReportFormCubit(repo, reporter: user, editing: incident),
          child: _ReportFormView(initial: incident),
        );
      },
    );
  }
}

class _ReportFormView extends StatefulWidget {
  const _ReportFormView({this.initial});

  final Incident? initial;

  @override
  State<_ReportFormView> createState() => _ReportFormViewState();
}

class _ReportFormViewState extends State<_ReportFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _description = TextEditingController(text: widget.initial?.description);
  late final _detail = TextEditingController();
  String? _building;

  @override
  void initState() {
    super.initState();
    // Split an existing "Block B — Room 204" back into building + detail.
    final loc = widget.initial?.location;
    if (loc != null) {
      final parts = loc.split(' — ');
      _building = AppConstants.campusLocations.contains(parts.first) ? parts.first : 'Other';
      _detail.text = _building == 'Other' ? loc : parts.skip(1).join(' — ');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _detail.dispose();
    super.dispose();
  }

  String get _location {
    final detail = _detail.text.trim();
    if (_building == null) return '';
    if (_building == 'Other') return detail;
    return detail.isEmpty ? _building! : '$_building — $detail';
  }

  Future<void> _pickPhoto(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final file = await ImagePicker().pickImage(source: source, imageQuality: 60, maxWidth: 1280);
      if (file != null && mounted) context.read<ReportFormCubit>().setPhoto(File(file.path));
    } catch (_) {
      if (mounted) showAppSnack(context, 'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}.', error: true);
    }
  }

  void _choosePhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Symbols.photo_camera_rounded),
            title: const Text('Take a photo'),
            onTap: () => _pickPhoto(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Symbols.photo_library_rounded),
            title: const Text('Choose from gallery'),
            onTap: () => _pickPhoto(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    context.read<ReportFormCubit>().submit(
          formValid: valid,
          title: _title.text,
          description: _description.text,
          location: _location,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportFormCubit>();
    final editing = cubit.isEditing;
    return BlocListener<ReportFormCubit, ReportFormState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == FormStatus.failure && state.error != null) {
          showAppSnack(context, state.error!, error: true);
        }
        if (state.status == FormStatus.success) {
          showAppSnack(context, editing ? 'Report updated.' : 'Report submitted. Staff have been notified.');
          if (editing) {
            context.pop();
          } else {
            context.pushReplacement(Routes.incident(state.createdId!));
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Symbols.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(editing ? 'Edit Report' : 'Report an Incident'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const _CategoryPicker(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                maxLength: Validators.titleMax,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. No water on the 2nd floor'),
                validator: Validators.title,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 4,
                maxLines: 8,
                maxLength: Validators.descriptionMax,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What happened, when, and who is affected?',
                  alignLabelWithHint: true,
                ),
                validator: Validators.description,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _building,
                decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Symbols.location_on_rounded)),
                items: [for (final l in AppConstants.campusLocations) DropdownMenuItem(value: l, child: Text(l))],
                onChanged: (v) => setState(() => _building = v),
                validator: (v) => v == null ? 'Choose where the issue is' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detail,
                decoration: InputDecoration(
                  labelText: _building == 'Other' ? 'Describe the location' : 'Room / floor (optional)',
                  hintText: _building == 'Other' ? 'e.g. Behind the main gate' : 'e.g. Room 204',
                ),
                validator: (v) => _building == 'Other' ? Validators.location(v) : null,
              ),
              const SizedBox(height: 20),
              _PhotoPicker(onPick: _choosePhotoSource),
              const SizedBox(height: 16),
              BlocBuilder<ReportFormCubit, ReportFormState>(
                buildWhen: (a, b) => a.isAnonymous != b.isAnonymous,
                builder: (context, state) => Card(
                  child: SwitchListTile(
                    value: state.isAnonymous,
                    onChanged: cubit.setAnonymous,
                    secondary: const Icon(Symbols.visibility_off_rounded),
                    title: const Text('Report anonymously'),
                    subtitle: const Text('Your name is hidden from other students. Staff can still see who reported it.'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<ReportFormCubit, ReportFormState>(
                builder: (context, state) => LoadingButton(
                  label: editing ? 'Save changes' : 'Submit Report',
                  icon: Symbols.send_rounded,
                  loading: state.isSubmitting,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final state = context.watch<ReportFormCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is the issue about?', style: t.titleMedium),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            for (final cat in IncidentCategory.values)
              _CategoryTile(
                category: cat,
                selected: state.category == cat,
                onTap: () => context.read<ReportFormCubit>().selectCategory(cat),
              ),
          ],
        ),
        if (state.showCategoryError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text('Choose a category', style: t.bodySmall?.copyWith(color: c.error)),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.selected, required this.onTap});

  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected ? c.onPrimary : c.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primary : c.iceSoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, color: fg, size: 26, fill: selected ? 1 : 0),
              const SizedBox(height: 6),
              Text(category.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: selected ? c.onPrimary : c.navy)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final state = context.watch<ReportFormCubit>().state;
    final current = state.photo?.path ?? state.existingPhotoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Photo', style: t.labelLarge),
          const SizedBox(width: 4),
          Text('(optional)', style: t.bodySmall),
        ]),
        const SizedBox(height: 8),
        if (current != null)
          Stack(children: [
            IncidentPhoto(url: current, fallbackIcon: Symbols.image_rounded, height: 180),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Remove photo',
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: context.read<ReportFormCubit>().removePhoto,
                icon: const Icon(Symbols.close_rounded, color: Colors.white),
              ),
            ),
          ])
        else
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPick,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.sky, width: 1.5),
              ),
              child: Column(children: [
                Icon(Symbols.add_a_photo_rounded, size: 30, color: c.primary),
                const SizedBox(height: 6),
                Text('Tap to add a photo', style: t.labelLarge?.copyWith(color: c.primary)),
                const SizedBox(height: 4),
                Text('JPG or PNG, up to 5 MB. Please avoid photographing people’s faces.',
                    style: t.bodySmall, textAlign: TextAlign.center),
              ]),
            ),
          ),
      ],
    );
  }
}
