import 'package:campus_incident_app/dev/fake_backend.dart';
import 'package:campus_incident_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _signIn(WidgetTester tester, String email) async {
  await tester.pumpWidget(CampusFixApp(backend: createFakeBackend(latency: Duration.zero)));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    // A phone-sized screen (360 x 780 logical pixels).
    final view = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher.views.first
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(view.reset);
  });

  testWidgets('login validates the ALU email domain', (tester) async {
    await tester.pumpWidget(CampusFixApp(backend: createFakeBackend(latency: Duration.zero)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'someone@gmail.com');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only @alustudent.com'), findsOneWidget);
  });

  testWidgets('a student signs in and lands on Home with their reports', (tester) async {
    await _signIn(tester, 'amina.hassan@alustudent.com');
    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('Report an Issue'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Water shortage'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Water shortage'), findsOneWidget);
  });

  testWidgets('staff sign in to the queue, not the student home', (tester) async {
    await _signIn(tester, 'jean.mugisha@alueducation.com');
    expect(find.text('Hello, Jean'), findsOneWidget);
    expect(find.text('Report an Issue'), findsNothing);
    expect(find.text('Needs attention'), findsOneWidget);
  });
}
