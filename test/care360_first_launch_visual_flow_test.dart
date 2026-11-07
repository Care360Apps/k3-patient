import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_first_language.dart';

void main() {
  testWidgets('First launch displays shipped identity and five language choices',
      (tester) async {
    String? accepted;
    await tester.pumpWidget(MaterialApp(
      home: Care360FirstLanguageScreen(
        onContinue: (code) async { accepted = code; },
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Care360'), findsOneWidget);
    expect(find.text('Welcome to Care360'), findsOneWidget);
    for (final code in ['en', 'ha', 'ig', 'yo', 'fr']) {
      expect(find.byKey(Key('first-language-$code')), findsOneWidget);
    }
    expect(find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName ==
            'assets/images/care360_master_logo.webp'), findsOneWidget);
    expect(find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is AssetImage &&
        (w.image as AssetImage).assetName ==
            'assets/images/care360_clinician_team.webp'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('first-language-ha')));
    await tester.tap(find.byKey(const Key('first-language-ha')));
    await tester.ensureVisible(find.byKey(
        const Key('first-language-continue')));
    await tester.tap(find.byKey(const Key('first-language-continue')));
    await tester.pumpAndSettle();
    expect(accepted, 'ha');
    expect(tester.takeException(), isNull);
  });

  testWidgets('French and large text remain usable on a narrow phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var completionCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.6),
        ),
        child: Care360FirstLanguageScreen(
          initialLanguage: 'ha',
          onContinue: (code) async {
            expect(code, 'fr');
            completionCount++;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('first-language-fr')));
    await tester.tap(find.byKey(const Key('first-language-fr')));
    await tester.ensureVisible(find.byKey(
        const Key('first-language-continue')));
    await tester.tap(find.byKey(const Key('first-language-continue')));
    await tester.pumpAndSettle();
    expect(completionCount, 1);
    expect(tester.takeException(), isNull);
  });

  test('Only new users see language setup; existing session routes retained',
      () {
    final main = File('lib/main.dart').readAsStringSync();
    final onboarding =
        File('lib/Screen/Onboarding/Onboarding.dart').readAsStringSync();
    final signIn =
        File('lib/Screen/Authentication/SignIn.dart').readAsStringSync();
    expect(main, contains('if (!hasSeenOnboarding)'));
    expect(main, contains('Care360FirstLanguageScreen('));
    expect(main, contains('care360_locale.setLocale(code)'));
    expect(main, contains('return isLoggedIn ? Home() : SignIn();'));
    expect(main, contains('builder: (_) => const OnboardingScreen()'));
    expect(onboarding, contains('Preferences.onboarding_seen, true'));
    expect(signIn, contains('Care360LanguagePicker('));
    expect(main, contains("ChangeLanguage': (context) => ChangeLanguage()"));
  });
}
