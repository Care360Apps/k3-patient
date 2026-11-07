import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_guide_shortcut.dart';

void main() {
  testWidgets('French locale displays and opens nonclinical Care360 Guide',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('fr', 'FR'),
      home: Scaffold(body: Care360GuideShortcut()),
    ));

    expect(find.text('Guide Care360'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-care360-guide')));
    await tester.pumpAndSettle();

    expect(find.text('Guide Care360'), findsOneWidget);
    expect(find.textContaining('Offline, curated app help'), findsOneWidget);
    expect(find.byKey(const Key('guide-ai-consent')), findsNothing);
  });

  testWidgets('Guide shortcut remains available with English locale',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('en', 'US'),
      home: Scaffold(body: Care360GuideShortcut()),
    ));
    expect(find.text('Care360 Guide'), findsOneWidget);
    expect(find.textContaining('not medical advice'), findsOneWidget);
  });
}
