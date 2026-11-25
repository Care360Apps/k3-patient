import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/brand/care360_partner_showcase.dart';
import '../lib/localization/language_localization.dart';

void main() {
  testWidgets('Empty backend feed has no default advert', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Care360PartnerShowcase(showGuideButton: false))));
    expect(find.text('MindCheck'), findsNothing);
    expect(find.byKey(const ValueKey('care360-partner-carousel')), findsNothing);
  });
  testWidgets('MindCheck opens only a clean external HTTPS destination', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Care360PartnerShowcase(
        slides: [Care360PartnerSlide(title: 'MindCheck', subtitle: 'SpeakOut Mental Health Outreach', url: Uri.parse('https://mindcheck.speakoutmentalhealth.org/'))],
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

  testWidgets('Help opens the curated AI Guide; generation is off in review',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Care360PartnerShowcase()),
    ));
    await tester.tap(find.text('Care360 Help'));
    await tester.pumpAndSettle();
    expect(find.text('Care360 Guide'), findsOneWidget);
    expect(find.textContaining('Offline, curated app help'), findsOneWidget);
    expect(find.byKey(const Key('guide-ai-consent')), findsNothing);
  });

  testWidgets('Sponsor remains for 9 seconds, rotates at 10; manual control works',
      (tester) async {
    Uri? opened;
    final first = Uri.parse('https://partner.example.org/');
    final second = Uri.parse('https://another.example.org/');
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(child: Care360PartnerShowcase(
        slides: [
          Care360PartnerSlide(title: 'Sponsor One',
            subtitle: 'Independent paid placement', url: first, sponsored: true),
          Care360PartnerSlide(title: 'Sponsor Two',
            subtitle: 'Independent paid placement', url: second, sponsored: true),
        ],
        openExternal: (uri) async { opened = uri; return true; },
      )),
    )));
    expect(find.text('1/2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('1/2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Sponsored'), findsWidgets);
    expect(find.text('Sponsor Two'), findsOneWidget);
    await tester.tap(find.text('Sponsor Two'));
    await tester.pump();
    expect(opened, second);
  });

  testWidgets('Reduced-motion preference disables sponsor autoplay',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(body: Care360PartnerShowcase(
        slides: [Care360PartnerSlide(
          title: 'Synthetic Sponsor',
          subtitle: 'Test placement only',
          url: Uri.parse('https://example.org/'),
          sponsored: true,
        ), Care360PartnerSlide(title: 'Second Sponsor', subtitle: 'Test', url: Uri.parse('https://example.org/second'))],
      )),
    )));
    expect(find.text('1/2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 11));
    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.byTooltip('Next partner'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('2/2'), findsOneWidget);
  });

  test('Partner links reject unsafe destinations and authenticated data', () {
    for (final url in [
      'http://partner.example.org', 'javascript:alert(1)',
      'https://localhost/', 'https://127.0.0.1:8000/',
      'https://example.org:8443/', 'https://alice@example.org/',
    ]) {
      expect(Care360PartnerSlide.safeDestination(url), isNull, reason: url);
    }
    expect(Care360PartnerSlide.safeDestination(
        'https://partner.example.org/offer?a=1')?.host, 'partner.example.org');
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    expect(home, isNot(contains('banner.addAll(response.data!)')));
    expect(home, isNot(contains('Uri.parse(bannerData.link!)')));
    expect(home, contains('banner = response.data ?? <Add>[]'));
    expect(home, contains('Care360PartnerShowcase('));
    expect(home, contains('showGuideButton: false'));
    expect(home, contains('const Care360GuideShortcut()'));
  });

  test('MindCheck is only displayed inside authenticated Patient home', () {
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    expect(home.contains('Care360PartnerShowcase('), isTrue);
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
