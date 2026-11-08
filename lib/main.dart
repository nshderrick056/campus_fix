import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/backend.dart';
import 'data/firebase/firebase_backend.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/incident_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'dev/fake_backend.dart';
import 'logic/auth/auth_cubit.dart';
import 'logic/theme/theme_cubit.dart';

/// Which data layer to use:
/// - in-memory demo data (default until Firebase is configured):
///   `flutter run`
/// - real Firebase + Cloudinary (after `flutterfire configure`):
///   `flutter run --dart-define=FAKE_BACKEND=false --dart-define-from-file=env.json`
const useFakeBackend = bool.fromEnvironment('FAKE_BACKEND', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // On Android, Firebase reads android/app/google-services.json (written by
  // `flutterfire configure`), so no options file needs importing here.
  final backend = useFakeBackend ? createFakeBackend() : await createFirebaseBackend();
  runApp(CampusFixApp(backend: backend));
}

class CampusFixApp extends StatelessWidget {
  const CampusFixApp({super.key, required this.backend});

  final Backend backend;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: backend.auth),
        RepositoryProvider<IncidentRepository>.value(value: backend.incidents),
        RepositoryProvider<NotificationRepository>.value(value: backend.notifications),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(backend.auth)),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: const _RouterApp(),
      ),
    );
  }
}

class _RouterApp extends StatefulWidget {
  const _RouterApp();

  @override
  State<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends State<_RouterApp> {
  late final GoRouter _router = createRouter(context.read<AuthCubit>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: _router,
    );
  }
}
