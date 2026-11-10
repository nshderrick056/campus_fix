import 'package:campus_incident_app/core/theme/app_colors.dart';
import 'package:campus_incident_app/presentation/widgets/incident_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

Widget _host(Widget child) => MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('expandable photo opens a full-screen zoomable viewer', (tester) async {
    await tester.pumpWidget(_host(const IncidentPhoto(
      url: 'missing.jpg',
      fallbackIcon: Symbols.chair_rounded,
      height: 200,
      expandable: true,
    )));

    await tester.tap(find.byType(IncidentPhoto));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });

  testWidgets('photo without expandable does not open the viewer', (tester) async {
    await tester.pumpWidget(_host(const IncidentPhoto(
      url: 'missing.jpg',
      fallbackIcon: Symbols.chair_rounded,
      size: 64,
    )));

    await tester.tap(find.byType(IncidentPhoto));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
