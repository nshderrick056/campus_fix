import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../logic/auth/auth_cubit.dart';
import '../../presentation/screens/alerts/alerts_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/verify_email_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/incident/incident_detail_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/report/report_form_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';
import '../../presentation/screens/staff/staff_queue_screen.dart';

/// Route paths, so screens never hard-code strings.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verify = '/verify';

  static const home = '/home';
  static const reports = '/reports';
  static const alerts = '/alerts';
  static const profile = '/profile';

  static const staffQueue = '/staff/queue';
  static const staffReports = '/staff/reports';
  static const staffProfile = '/staff/profile';

  static const newReport = '/report/new';
  static String incident(String id) => '/incident/$id';
  static String editIncident(String id) => '/incident/$id/edit';

  static const _authPages = {login, register};
  static const _studentOnly = {home, reports, alerts, profile, newReport};
}

/// Decides where a user may go based on [AuthState]. Pure, so it is unit-tested.
String? authRedirect(AuthState auth, String location) {
  switch (auth.status) {
    case AuthStatus.unknown:
      return location == Routes.splash ? null : Routes.splash;
    case AuthStatus.signedOut:
      return Routes._authPages.contains(location) ? null : Routes.login;
    case AuthStatus.unverified:
      return location == Routes.verify ? null : Routes.verify;
    case AuthStatus.signedIn:
      final home = auth.isStaff ? Routes.staffQueue : Routes.home;
      final onEntryPage = location == Routes.splash ||
          location == Routes.verify ||
          Routes._authPages.contains(location);
      if (onEntryPage) return home;
      if (auth.isStaff && Routes._studentOnly.contains(location)) return home;
      if (auth.isStaff && location.endsWith('/edit')) return home;
      if (!auth.isStaff && location.startsWith('/staff')) return home;
      return null;
  }
}

GoRouter createRouter(AuthCubit auth) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _StreamListenable(auth.stream),
    redirect: (context, state) => authRedirect(auth.state, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.verify, builder: (_, _) => const VerifyEmailScreen()),
      GoRoute(path: Routes.newReport, builder: (_, _) => const ReportFormScreen()),
      GoRoute(
        path: '/incident/:id',
        builder: (_, s) => IncidentDetailScreen(incidentId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, s) => ReportFormScreen(editId: s.pathParameters['id']),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell, staff: false),
        branches: [
          _branch(Routes.home, const HomeScreen()),
          _branch(Routes.reports, const ReportsScreen()),
          _branch(Routes.alerts, const AlertsScreen()),
          _branch(Routes.profile, const ProfileScreen()),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell, staff: true),
        branches: [
          _branch(Routes.staffQueue, const StaffQueueScreen()),
          _branch(Routes.staffReports, const ReportsScreen(staffView: true)),
          _branch(Routes.staffProfile, const ProfileScreen()),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch(String path, Widget screen) =>
    StatefulShellBranch(routes: [GoRoute(path: path, builder: (_, _) => screen)]);

/// Re-runs the router's redirect whenever the auth state changes.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
