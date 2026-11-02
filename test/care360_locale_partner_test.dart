import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/brand/care360_partner_showcase.dart';
import '../lib/localization/language_localization.dart';

void main() {
  testWidgets('MindCheck opens only a clean external HTTPS destination', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Care360PartnerShowcase(
        openExternal: (url) async { opened = url; return true; },
      )),
    ));
    await tester.tap(find.text('MindCheck'));
    await tester.pump();
    expect(opened.toString(), 'https://mindcheck.speakoutmentalhealth.org/');
    expect(opened!.query, isEmpty);
    expect(opened!.fragment, isEmpty);
    expect(find.textContaining('SpeakOut Mental Health Outreach'), findsOneWidget);
  });

  testWidgets('Help is informative and never calls a model', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Care360PartnerShowcase()),
    ));
    await tester.tap(find.text('Care360 Help'));
    await tester.pumpAndSettle();
    expect(find.textContaining('offline help guide'), findsOneWidget);
    expect(find.textContaining('not a generative AI chat'), findsOneWidget);
  });

  test('MindCheck is only displayed inside authenticated Patient home', () {
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    expect(home.contains('Care360PartnerShowcase()'), isTrue);
    expect(home.contains(
      'SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true'),
      isTrue);
    expect(home.contains('SharedPreferenceHelper.peekSecureString(Preferences.auth_token) != null'), isTrue);
    final auth = File('lib/brand/care360_entry.dart').readAsStringSync();
    expect(auth.contains('MindCheck'), isFalse);
  });

  test('All four added languages fall back to the original English strings', () async {
    final en = LanguageLocalization(const Locale('en', 'US'));
    await en.load();
    for (final lang in ['ha', 'ig', 'yo', 'fr']) {
      final instance = LanguageLocalization(Locale(lang));
      await instance.load();
      expect(instance.getTranslateValue('changeLanguage_title'), isNotNull);
      expect(instance.getTranslateValue('changeLanguage_title'), isNot(
        en.getTranslateValue('changeLanguage_title')));
      // No fake translations: missing keys remain the exact English content.
      final fallback = en.getTranslateValue('bookAppointment_illness_validator2');
      expect(instance.getTranslateValue('bookAppointment_illness_validator2'), fallback);
    }
  });
}
