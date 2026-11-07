import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/placeholder_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(firebase): after running `flutterfire configure` (see README.md),
  // initialise Firebase here:
  //
  //   import 'package:firebase_core/firebase_core.dart';
  //   import 'firebase_options.dart';
  //
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );

  runApp(const CampusFixApp());
}

class CampusFixApp extends StatelessWidget {
  const CampusFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // TODO(router): replace with MaterialApp.router + go_router config
      // in lib/core/router/ once auth and feature screens exist.
      home: const PlaceholderScreen(),
    );
  }
}
