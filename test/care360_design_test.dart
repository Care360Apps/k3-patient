import 'package:doctro_patient/Screen/Onboarding/Onboarding.dart';
import 'package:doctro_patient/const/care360_theme.dart';
import 'package:doctro_patient/widgets/care360_quick_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Care360 onboarding advances through the existing three steps',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: Care360Theme.light,
      home: const OnboardingScreen(),
    ));
    expect(find.text('Care that fits your life.'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('NIGERIA TO THE WORLD'), findsOneWidget);
    expect(find.text('A product of CNU Medical Institute'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Healthcare, made simpler.'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('The right care starts here.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('Care360 onboarding fits a compact portrait screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: Care360Theme.light,
      home: const OnboardingScreen(),
    ));
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quick access uses existing navigation routes', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: Care360Theme.light,
      home: const Scaffold(body: SingleChildScrollView(child: Care360QuickAccess())),
      routes: {
        'Specialist': (_) => const Scaffold(body: Text('Existing specialist destination')),
      },
    ));
    expect(find.text('Find doctors'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('Pharmacies'), findsOneWidget);
    expect(find.text('Hospitals'), findsOneWidget);

    await tester.tap(find.text('Find doctors'));
    await tester.pumpAndSettle();
    expect(find.text('Existing specialist destination'), findsOneWidget);
  });
}
