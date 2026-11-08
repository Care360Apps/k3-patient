import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_patient_service_grid.dart';
import 'package:doctro_patient/brand/care360_first_language.dart';
import 'package:doctro_patient/brand/care360_service_intro.dart';
import 'package:doctro_patient/localization/language_localization.dart';
import 'package:doctro_patient/localization/care360_framework_locale_fallback.dart';
import 'package:doctro_patient/workforce/workforce_api.dart';
import 'package:doctro_patient/workforce/workforce_landing.dart';

void _noopService(Care360ServiceDestination _) {}

void main() {
  const supported = ['en', 'ha', 'ig', 'yo', 'fr'];
  const requiredKeys = [
    'care360_services_heading', 'care360_services_intro',
    'care360_service_hospitals',
    'care360_service_hospitals_description',
    'care360_service_doctors',
    'care360_service_doctors_description',
    'care360_service_providers',
    'care360_service_providers_description',
    'care360_service_pharmacies',
    'care360_service_pharmacies_description',
    'care360_service_laboratories',
    'care360_service_laboratories_description',
    'care360_service_appointments',
    'care360_service_appointments_description',
    'care360_dir_hospitals_description',
    'care360_dir_doctors_description',
    'care360_dir_providers_description',
    'care360_dir_pharmacies_description',
    'care360_dir_laboratories_description',
    'care360_workforce_title', 'care360_workforce_subtitle',
  ];

  test('All five locales contain nonempty healthcare-navigation labels', () {
    for (final locale in supported) {
      final file = File('lib/localization/languages/$locale.json');
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in requiredKeys) {
        expect(json[key], isA<String>(), reason: '$locale.$key');
        expect((json[key] as String).trim(), isNotEmpty,
            reason: '$locale.$key');
      }
    }
    // Navigation only: does not assert complete clinical translations.
    final code = File('lib/brand/care360_patient_service_grid.dart')
        .readAsStringSync();
    expect(code, contains('care360NavigationText(context,'));
    expect(code, contains('maxLines: 2'));
  });

  Widget appFor(String code) => MaterialApp(
    locale: Locale(code),
    supportedLocales: const [
      Locale('en'), Locale('ha'), Locale('ig'), Locale('yo'), Locale('fr'),
    ],
    localizationsDelegates: const [
      Care360MaterialFallbackDelegate(),
      Care360WidgetsFallbackDelegate(),
      Care360CupertinoFallbackDelegate(),
      LanguageLocalization.delegate,
    ],
    home: Scaffold(body: SingleChildScrollView(
      child: Column(children: [
        Care360PatientServiceGrid(onOpen: (_) {}),
        const Care360ServiceIntro(
          title: 'Hospitals',
          titleKey: 'care360_service_hospitals',
          description: 'Explore healthcare facilities',
          descriptionKey: 'care360_dir_hospitals_description',
          icon: Icons.local_hospital_outlined,
        ),
        Care360WorkforceHomeTile(onTap: () {}),
      ]),
    )),
  );

  testWidgets('Language selection rerenders healthcare destinations',
      (tester) async {
    await tester.pumpWidget(appFor('ha'));
    await tester.pumpAndSettle();
    expect(find.text('Bincika ayyukan lafiya'), findsOneWidget);
    expect(find.text('Asibitoci'), findsWidgets);
    expect(find.text('Healthcare careers and hiring — pilot preview'),
        findsNothing);

    await tester.pumpWidget(appFor('fr'));
    await tester.pumpAndSettle();
    expect(find.text('Explorer les services de santé'), findsOneWidget);
    expect(find.text('Hôpitaux'), findsWidgets);
    expect(find.text('Emplois et recrutement en santé — aperçu pilote'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('The shipped Yoruba bundle is loaded by the real locale delegate',
      () async {
    final localization = LanguageLocalization(const Locale('yo'));
    await localization.load();
    expect(localization.getTranslateValue('care360_services_heading'),
        'Ṣàwárí àwọn iṣẹ́ ìlera');
    expect(localization.getTranslateValue('care360_service_hospitals'),
        'Ilé ìwòsàn');
  });

  testWidgets('Navigation remains usable on a 320px device with large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 650));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Care360PatientServiceGrid(onOpen: _noopService),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('care360-services-heading')), findsOneWidget);
    expect(find.text('Explore healthcare'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('care360-service-appointments')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('First-launch language choice immediately translates welcome copy',
      (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Care360FirstLanguageScreen(
        onContinue: (value) async { selected = value; },
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Care360'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('first-language-ha')));
    await tester.tap(find.byKey(const Key('first-language-ha')));
    await tester.pumpAndSettle();
    expect(find.text('Barka da zuwa Care360'), findsOneWidget);
    expect(find.text('Ci gaba'), findsOneWidget);

    await tester.ensureVisible(
        find.byKey(const Key('first-language-continue')));
    await tester.tap(find.byKey(const Key('first-language-continue')));
    await tester.pumpAndSettle();
    expect(selected, 'ha');

    await tester.ensureVisible(find.byKey(const Key('first-language-fr')));
    await tester.tap(find.byKey(const Key('first-language-fr')));
    await tester.pumpAndSettle();
    expect(find.text('Bienvenue sur Care360'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Workforce rejects plaintext remote and loopback credentials by default',
      () async {
    for (final origin in [
      'http://workforce.example.test/api/',
      'http://127.0.0.1:9/api/',
      'http://192.168.100.38:8000/api/',
    ]) {
      final api = WorkforceApi(dio: Dio(BaseOptions(baseUrl: origin)));
      expect(await api.applicationsOpen(), false);
      await expectLater(
        api.register(
          name: 'Synthetic User',
          email: 'synthetic@example.test',
          password: 'not-a-real-password',
          accountType: 'candidate',
          adultAttestation: true,
          acceptedTerms: true,
        ),
        throwsA(isA<WorkforceApiException>()),
      );
    }
  });

  test('Workforce authorization stays separate from clinical credentials', () {
    final source = File('lib/workforce/workforce_api.dart').readAsStringSync();
    expect(source, contains('K3_ALLOW_LOCAL_WORKFORCE_HTTP'));
    expect(source, contains('_requireSecureWorkforceOrigin();'));
    expect(source, contains("error.response?.statusCode == 401"));
    expect(source, contains('await _storage.delete(key: tokenKey)'));
    expect(source, isNot(contains('Preferences.auth_token')));
    expect(source, isNot(contains('RetroApi().dioData()')));
    expect(source, contains("static const tokenKey = 'care360_workforce_session'"));
  });
}
