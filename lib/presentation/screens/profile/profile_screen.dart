import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/incidents/my_reports_cubit.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../models/incident_status.dart';
import '../../widgets/common.dart';

/// Account details, the student's report counts, appearance and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need your ALU email and password to sign back in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<AuthCubit>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user)!;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('Profile', style: t.titleLarge),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  UserAvatar(initials: user.initials, radius: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Text(user.displayName, style: t.titleSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: c.iceSoft, borderRadius: BorderRadius.circular(999)),
                          child: Text(user.role.label, style: t.labelSmall?.copyWith(color: c.primary)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      _IconLine(icon: Symbols.mail_rounded, text: user.email),
                      if (user.department != null) _IconLine(icon: Symbols.school_rounded, text: user.department!),
                    ]),
                  ),
                ]),
              ),
            ),
            if (!user.isStaff) ...[
              const SizedBox(height: 16),
              const _MyCounts(),
            ],
            const SizedBox(height: 16),
            Card(
              child: Column(children: [
                if (!user.isStaff)
                  _MenuTile(icon: Symbols.description_rounded, label: 'My reports', onTap: () => context.go(Routes.reports)),
                const _ThemeTile(),
                _MenuTile(
                  icon: Symbols.shield_rounded,
                  label: 'Privacy & anonymity',
                  onTap: () => _info(context, 'Privacy & anonymity',
                      'Anonymous reports hide your name from other students. Campus staff can always see who reported an issue so they can follow up. Please avoid photographing people.'),
                ),
                _MenuTile(
                  icon: Symbols.menu_book_rounded,
                  label: 'Reporting guidelines',
                  onTap: () => _info(context, 'Reporting guidelines',
                      'Report real issues on campus only. Give a clear title, the exact location and what is affected. Duplicate or abusive reports may be rejected by staff.'),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Symbols.logout_rounded),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: 12),
            Text('${AppConstants.appName} v1.0 · ALU Rwanda', style: t.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _info(BuildContext context, String title, String body) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
        ),
      );
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(children: [
        Icon(icon, size: 14, color: context.colors.textMuted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: t.bodySmall, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _MyCounts extends StatelessWidget {
  const _MyCounts();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<MyReportsCubit>().state;
    final c = context.colors;
    return Row(children: [
      Expanded(child: StatCard(icon: Symbols.description_rounded, value: '${s.total}', label: 'Total', foreground: c.primary, background: c.iceSoft)),
      const SizedBox(width: 8),
      Expanded(
          child: StatCard(
              icon: IncidentStatus.inProgress.icon,
              value: '${s.count(IncidentStatus.inProgress)}',
              label: 'In Progress',
              foreground: c.inProgress,
              background: c.inProgressBg)),
      const SizedBox(width: 8),
      Expanded(
          child: StatCard(
              icon: IncidentStatus.resolved.icon,
              value: '${s.count(IncidentStatus.resolved)}',
              label: 'Resolved',
              foreground: c.resolved,
              background: c.resolvedBg)),
    ]);
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: c.iceSoft, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 20, color: c.primary),
      ),
      title: Text(label),
      trailing: Icon(Symbols.chevron_right_rounded, color: c.placeholder),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: c.iceSoft, borderRadius: BorderRadius.circular(10)),
          child: Icon(Symbols.contrast_rounded, size: 20, color: c.primary),
        ),
        const SizedBox(width: 16),
        const Expanded(child: Text('Appearance')),
        SegmentedButton<ThemeMode>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment(value: ThemeMode.light, icon: Icon(Symbols.light_mode_rounded), tooltip: 'Light'),
            ButtonSegment(value: ThemeMode.system, icon: Icon(Symbols.brightness_auto_rounded), tooltip: 'System'),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Symbols.dark_mode_rounded), tooltip: 'Dark'),
          ],
          selected: {mode},
          onSelectionChanged: (s) => context.read<ThemeCubit>().set(s.first),
        ),
      ]),
    );
  }
}
