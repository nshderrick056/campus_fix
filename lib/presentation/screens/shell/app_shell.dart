import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/incident_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../logic/auth/auth_cubit.dart';
import '../../../logic/incidents/incidents_cubit.dart';
import '../../../logic/incidents/my_reports_cubit.dart';
import '../../../logic/notifications/notifications_cubit.dart';

/// Signed-in frame: provides the per-user cubits and shows the bottom bar.
/// Students: Home · Reports · (+) · Alerts · Profile. Staff: Queue · All Reports · Profile.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell, required this.staff});

  final StatefulNavigationShell shell;
  final bool staff;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthCubit c) => c.state.user);
    if (user == null) return const SizedBox.shrink(); // router is redirecting
    final incidents = context.read<IncidentRepository>();
    return MultiBlocProvider(
      key: ValueKey(user.uid),
      providers: [
        // Browse list (Reports / All Reports). The staff Queue has its own.
        BlocProvider(create: (_) => IncidentsCubit(incidents)),
        BlocProvider(create: (_) => MyReportsCubit(incidents, user.uid)),
        BlocProvider(create: (_) => NotificationsCubit(context.read<NotificationRepository>(), user.uid)),
      ],
      child: staff ? _StaffScaffold(shell: shell) : _StudentScaffold(shell: shell),
    );
  }
}

class _StudentScaffold extends StatelessWidget {
  const _StudentScaffold({required this.shell});

  final StatefulNavigationShell shell;

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final unread = context.select((NotificationsCubit c) => c.state.unread);
    final c = context.colors;
    return Scaffold(
      body: shell,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Report an issue',
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () => context.push(Routes.newReport),
        child: const Icon(Symbols.add_rounded, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 68,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            _NavItem(icon: Symbols.home_rounded, label: 'Home', selected: shell.currentIndex == 0, onTap: () => _go(0)),
            _NavItem(icon: Symbols.description_rounded, label: 'Reports', selected: shell.currentIndex == 1, onTap: () => _go(1)),
            const SizedBox(width: 72),
            _NavItem(
              icon: Symbols.notifications_rounded,
              label: 'Alerts',
              badge: unread,
              selected: shell.currentIndex == 2,
              onTap: () => _go(2),
            ),
            _NavItem(icon: Symbols.person_rounded, label: 'Profile', selected: shell.currentIndex == 3, onTap: () => _go(3)),
          ],
        ),
      ),
    );
  }
}

class _StaffScaffold extends StatelessWidget {
  const _StaffScaffold({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: c.deep,
          indicatorColor: c.onHero.withValues(alpha: 0.14),
          iconTheme: WidgetStateProperty.resolveWith(
              (s) => IconThemeData(color: s.contains(WidgetState.selected) ? c.sky : c.ice)),
          labelTextStyle: WidgetStateProperty.resolveWith((s) => Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: s.contains(WidgetState.selected) ? c.onHero : c.ice)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Symbols.inbox_rounded), label: 'Queue'),
            NavigationDestination(icon: Icon(Symbols.description_rounded), label: 'All Reports'),
            NavigationDestination(icon: Icon(Symbols.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.primary : c.textMuted;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: badge > 0 ? '$label, $badge unread' : label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                backgroundColor: c.error,
                child: Icon(icon, color: color, fill: selected ? 1 : 0),
              ),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
