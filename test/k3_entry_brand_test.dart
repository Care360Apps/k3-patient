import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/brand/care360_entry.dart';
import '../lib/brand/care360_global_language.dart';

void main() {
  testWidgets(
    'persistent language button works above Navigator without an Overlay error',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      String? changedTo;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, navigatorChild) => Stack(
          children: [
            if (navigatorChild != null) navigatorChild,
            PositionedDirectional(
              end: 10,
              bottom: 64,
              child: Care360GlobalLanguageSwitch(
                rootNavigatorKey: navigatorKey,
                onSelect: (languageCode) async {
                  changedTo = languageCode;
                },
              ),
            ),
          ],
        ),
        home: const Scaffold(body: Center(child: Text('Sign-in screen'))),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Sign-in screen'), findsOneWidget);
      expect(find.byKey(const Key('care360-language-every-screen')), findsOneWidget);
      await tester.tap(find.byKey(const Key('care360-language-every-screen')));
      await tester.pumpAndSettle();
      expect(find.text('Choose language'), findsOneWidget);
      await tester.tap(find.text('Hausa'));
      await tester.pumpAndSettle();
      expect(changedTo, 'ha');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CNU attribution opens the institute HTTPS site', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CnuAttribution(
      openLink: (uri) async { opened = uri; return true; },
    ))));
    await tester.tap(find.text('CNU Medical Institute'));
    await tester.pump();
    expect(opened.toString(), 'https://www.cnumedical.com/');
  });

  for (final professional in [false, true]) {
    testWidgets('welcome remains usable at 320px and larger text: $professional', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var completed = 0;
      await tester.pumpWidget(MaterialApp(home: MediaQuery(
        data: const MediaQueryData(size: Size(320, 568), textScaler: TextScaler.linear(1.6)),
        child: Care360Welcome(professional: professional, onComplete: () async { completed++; }),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(professional ? 'Care360 Plus' : 'Care360 Patient'), findsOneWidget);
      // All three onboarding steps must use distinct bundled photos.
      final photos = professional
          ? ['care360_clinician_team.webp', 'care360_appointments.webp', 'care360_family_care.webp']
          : ['care360_family_care.webp', 'care360_appointments.webp', 'care360_clinician_team.webp'];
      void expectPhoto(int index) {
        expect(find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName.endsWith(photos[index])),
          findsOneWidget);
      }
      expectPhoto(0);
      for (var i = 0; i < 2; i++) {
        await tester.ensureVisible(find.text('Continue'));
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expectPhoto(i + 1);
      }
      await tester.ensureVisible(find.text('Get started'));
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      expect(completed, 1);
      await tester.ensureVisible(find.text('CNU Medical Institute'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Skip uses the same completion flow', (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(home: Care360Welcome(
      professional: false, onComplete: () async { completed++; },
    )));
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(completed, 1);
  });

  testWidgets('sign-in shell scrolls to fields and attribution with keyboard space', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(size: Size(320, 568), viewInsets: EdgeInsets.only(bottom: 260)),
      child: Care360AuthShell(professional: true, child: Column(children: [
        const TextField(decoration: InputDecoration(labelText: 'Email')),
        const TextField(decoration: InputDecoration(labelText: 'Password')),
        FilledButton(onPressed: () {}, child: const Text('Sign in')),
      ])),
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Sign in'));
    await tester.ensureVisible(find.text('CNU Medical Institute'));
    expect(find.byWidgetPredicate((widget) =>
      widget is Image && widget.image is AssetImage &&
      (widget.image as AssetImage).assetName.endsWith('care360_clinician_team.webp')),
      findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
