import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/Screen/Onboarding/Onboarding.dart';

void main() {
  testWidgets('offline intro starts on the real first page and skips without services', (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onComplete: () => completed++),
    ));
    expect(find.text('Access our Online Consultation'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline intro advances through every page before completion', (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScreen(onComplete: () => completed++),
    ));
    for (var page = 0; page < 2; page++) {
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(completed, 0);
    }
    expect(find.text('Find a lot of specialist doctors in one place'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pump();
    expect(completed, 1);
    expect(tester.takeException(), isNull);
  });
}
