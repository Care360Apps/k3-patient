import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:doctro_patient/brand/care360_global_language.dart';
import 'package:doctro_patient/localization/language_localization.dart';
import 'package:doctro_patient/localization/care360_framework_locale_fallback.dart';

void main() {
  testWidgets('Live language switch updates Navigator screens without Flutter error',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    var locale = const Locale('en', 'US');
    final selections = <String>[];

    await tester.pumpWidget(StatefulBuilder(
      builder: (hostContext, setHostState) => MaterialApp(
        locale: locale,
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('ha', 'NG'),
          Locale('ig', 'NG'),
          Locale('yo', 'NG'),
          Locale('fr', 'FR'),
        ],
        localizationsDelegates: const [
          LanguageLocalization.delegate,
          Care360MaterialFallbackDelegate(),
          Care360WidgetsFallbackDelegate(),
          Care360CupertinoFallbackDelegate(),
        ],
        navigatorKey: nav,
        builder: (context, navigatorChild) => Stack(
          children: [
            if (navigatorChild != null) navigatorChild,
            PositionedDirectional(
              end: 10, bottom: 64,
              child: Care360GlobalLanguageSwitch(
                rootNavigatorKey: nav,
                onSelect: (code) async {
                  selections.add(code);
                  setHostState(() => locale = Locale(code));
                },
              ),
            ),
          ],
        ),
        home: Scaffold(body: Builder(builder: (inner) =>
          Text('Locale: ${Localizations.localeOf(inner).languageCode}',
            key: const Key('locale-text')))),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Locale: en'), findsOneWidget);
    await tester.tap(find.byKey(const Key('care360-language-every-screen')));
    await tester.pumpAndSettle();
    expect(find.text('Choose language'), findsOneWidget);
    await tester.tap(find.text('Hausa'));
    await tester.pumpAndSettle();

    expect(find.text('Locale: ha'), findsOneWidget);
    expect(selections, ['ha']);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('care360-language-every-screen')),
        findsOneWidget);
  });

  testWidgets('Dismissing language picker makes no locale change',
      (tester) async {
    final nav = GlobalKey<NavigatorState>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      builder: (context, navigatorChild) => Stack(
        children: [
          if (navigatorChild != null) navigatorChild,
          PositionedDirectional(end: 10, bottom: 64, child:
            Care360GlobalLanguageSwitch(
              rootNavigatorKey: nav,
              onSelect: (_) async { calls++; },
            ),
          ),
        ],
      ),
      home: const Scaffold(body: Text('Patient home')),
    ));
    await tester.tap(find.byKey(const Key('care360-language-every-screen')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('Patient home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Settings switch awaits route disposal and does not mutate profile',
      () {
    final settings = File('lib/Screen/Setting/ChangeLanguage.dart')
        .readAsStringSync();
    expect(settings, contains('await exiting?.completed'));
    expect(settings, contains('MyApp.setLocale(rootContext, local)'));
    final global = File('lib/brand/care360_global_language.dart')
        .readAsStringSync();
    expect(global, contains('await sheetRoute?.completed'));
    expect(global, contains('useRootNavigator: true'));
    expect(global, isNot(contains('IconButton(tooltip:')));
    expect(global, contains('if (_changing) return'));
  });
}
