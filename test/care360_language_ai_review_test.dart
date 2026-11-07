import 'dart:io';

import 'package:doctro_patient/ai/care360_guide_screen.dart';
import 'package:doctro_patient/diagnostics/k3_startup_diagnostics.dart';
import 'package:doctro_patient/preview/care360_offline_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Care360 guide only accepts fixed navigation topics, not patient prompts', () {
    final guide = File('lib/ai/care360_guide_screen.dart').readAsStringSync();
    final signIn = File('lib/Screen/Authentication/SignIn.dart').readAsStringSync();
    final signUp = File('lib/Screen/Authentication/signup.dart').readAsStringSync();
    final showcase = File('lib/brand/care360_partner_showcase.dart').readAsStringSync();
    final locale = File('lib/localization/localization_constant.dart').readAsStringSync();

    expect(signIn, contains('Care360LanguagePicker('));
    expect(signUp, contains('Care360LanguagePicker('));
    expect(signUp, contains("items: const ['Male', 'Female'].map("));
    expect(signUp, contains('"gender": _selectGender'));
    expect(signUp, isNot(contains('items: gender.map(')));
    expect(locale, contains('await SharedPreferenceHelper.setString('));
    expect(showcase, contains('Care360GuideScreen(allowRemote: true)'));
    expect(guide, contains("bool.fromEnvironment('K3_AI_GUIDE_PILOT', defaultValue: false)"));
    expect(guide, contains("body: jsonEncode({'topic': _topic, 'language': _language})"));
    expect(guide, contains('if (!_canConnect || !_consent)'));
    for (final forbidden in [
      'K3_AI_GEMINI_API_KEY',
      'patientMedicalHistory',
      'freeformPrompt',
      'symptomController',
      'firebase-service-account',
    ]) {
      expect(guide, isNot(contains(forbidden)));
    }
  });

  testWidgets('curated Care360 navigation works without any AI connection',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: Care360GuideScreen(allowRemote: false),
    ));
    expect(find.textContaining('Offline, curated app help'), findsOneWidget);
    expect(find.byKey(const Key('guide-ai-consent')), findsNothing);

    // These controls sit below the first viewport on a compact phone.
    // dragUntilVisible works even when a ListView child is not laid out yet.
    final list = find.byType(ListView);
    final show = find.byKey(const Key('care360-guide-show'));
    await tester.dragUntilVisible(show, list, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(show);
    await tester.pumpAndSettle();
    final answer = find.byKey(const Key('care360-guide-answer'));
    await tester.dragUntilVisible(answer, list, const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(find.textContaining('Create a patient account'), findsOneWidget);

    // Choose a different fixed topic without typing any free-form health data.
    final partners = find.byKey(const Key('guide-topic-partners'));
    await tester.dragUntilVisible(partners, list, const Offset(0, 160));
    await tester.pumpAndSettle();
    await tester.tap(partners);
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(show, list, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(show);
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(answer, list, const Offset(0, -160));
    await tester.pumpAndSettle();
    expect(find.textContaining('SpeakOut Mental Health'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  if (k3OfflineSynthetic) {
    testWidgets('BlueStacks review language is interactive without clinical data',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(
        home: Care360OfflineDashboard(),
      ));
      await tester.tap(find.byKey(const Key('care360-language-picker')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français').last);
      await tester.pumpAndSettle();
      expect(find.text('De meilleurs soins, plus près de vous.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final guide = find.byKey(const Key('preview-care360-guide'));
      await tester.dragUntilVisible(
          guide, find.byKey(const Key('offline-dashboard-scroll')),
          const Offset(0, -180));
      await tester.pumpAndSettle();
      await tester.tap(guide);
      await tester.pumpAndSettle();
      expect(find.text('Guide Care360'), findsOneWidget);
      expect(find.textContaining('Generative AI is not enabled'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
