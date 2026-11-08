import 'package:campus_incident_app/core/theme/app_colors.dart';
import 'package:campus_incident_app/core/theme/app_theme.dart';
import 'package:campus_incident_app/dev/fake_backend.dart';
import 'package:campus_incident_app/main.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // No network in tests: fonts fall back to the default instead of downloading
  // (google_fonts logs a "not found in assets" line per font; harmless).
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme', () {
    for (final (name, theme, palette, brightness) in [
      ('light', AppTheme.light, AppColors.light, Brightness.light),
      ('dark', AppTheme.dark, AppColors.dark, Brightness.dark),
    ]) {
      test('$name: Material 3, palette and AppColors extension', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
        expect(theme.extension<AppColors>(), palette);
        expect(theme.colorScheme.primary, palette.primary);
        expect(theme.colorScheme.onPrimary, palette.onPrimary);
        expect(theme.colorScheme.error, palette.error);
        expect(theme.scaffoldBackgroundColor, palette.surface);
        expect(theme.cardTheme.color, palette.card);
      });

      test('$name: shape tokens', () {
        final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(cardShape.borderRadius, BorderRadius.circular(16));

        final input = theme.inputDecorationTheme.border! as OutlineInputBorder;
        expect(input.borderRadius, BorderRadius.circular(12));

        expect(theme.chipTheme.shape, isA<StadiumBorder>());
      });
    }

    test('dark primary buttons are sky blue with dark navy text', () {
      final style = AppTheme.dark.filledButtonTheme.style!;
      expect(style.backgroundColor!.resolve({}), const Color(0xFF60C1E5));
      expect(style.foregroundColor!.resolve({}), const Color(0xFF0B1A2E));
    });
  });

  group('enums', () {
    test('IncidentStatus round-trips Firestore values', () {
      for (final status in IncidentStatus.values) {
        expect(IncidentStatus.fromValue(status.value), status);
      }
      expect(IncidentStatus.inProgress.value, 'in_progress');
      expect(IncidentStatus.submitted.isEditableByReporter, isTrue);
      expect(IncidentStatus.resolved.isEditableByReporter, isFalse);
    });

    test('IncidentCategory has the 8 agreed categories', () {
      expect(
        IncidentCategory.values.map((c) => c.label),
        ['Facilities', 'Water', 'Electricity', 'Safety', 'Sanitation', 'Furniture', 'IT & Wi-Fi', 'Other'],
      );
      for (final category in IncidentCategory.values) {
        expect(IncidentCategory.fromValue(category.value), category);
      }
      expect(IncidentCategory.fromValue('unknown'), IncidentCategory.other);
    });
  });

  testWidgets('signed-out app boots to the login screen', (tester) async {
    await tester.pumpWidget(CampusFixApp(backend: createFakeBackend(latency: Duration.zero)));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back!'), findsOneWidget);
  });

  testWidgets('app follows the system dark mode', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(CampusFixApp(backend: createFakeBackend(latency: Duration.zero)));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Welcome Back!'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(context.colors, AppColors.dark);
  });

  testWidgets('the theme toggle switches dark to light', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(CampusFixApp(backend: createFakeBackend(latency: Duration.zero)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to light mode'));
    await tester.pumpAndSettle();

    expect(Theme.of(tester.element(find.text('Welcome Back!'))).brightness, Brightness.light);
  });
}
