import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_nearby_care_hero.dart';

void main() {
  testWidgets('Nigerian-first care hero retains working Nearby Care action',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Care360NearbyCareHero(
        onExplore: () => opened++,
      )),
    ));

    expect(find.text('Care closer to home'), findsOneWidget);
    expect(find.text('Find nearby care'), findsOneWidget);
    expect(find.byKey(const Key('home-find-nearby-care')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-find-nearby-care')));
    expect(opened, 1);
  });

  testWidgets('Healthcare hero stays usable on narrow screens with larger text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 680));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Scaffold(body: SingleChildScrollView(
          child: Care360NearbyCareHero(onExplore: () {}),
        )),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const Key('home-find-nearby-care')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
