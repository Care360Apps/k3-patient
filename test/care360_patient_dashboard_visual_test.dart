import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_patient_service_grid.dart';

void main() {
  testWidgets('Healthcare services render without filler or duplicates',
      (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      SingleChildScrollView(child: Care360PatientServiceGrid(
        onHospitals: () => opened.add('Hospitals'),
        onPharmacies: () => opened.add('Pharmacies'),
        onDoctors: () => opened.add('Doctors'),
        onProviders: () => opened.add('Providers'),
        onLabs: () => opened.add('Labs'),
        onWorkforce: () => opened.add('Workforce'),
      )),
    )));
    for (final name in [
      'Hospitals', 'Pharmacies', 'Doctors', 'Providers', 'Labs', 'Workforce'
    ]) {
      expect(find.text(name), findsOneWidget);
    }
    await tester.ensureVisible(find.byKey(const Key('care360-service-hospitals')));
    await tester.tap(find.byKey(const Key('care360-service-hospitals')));
    await tester.ensureVisible(find.byKey(const Key('care360-service-workforce')));
    await tester.tap(find.byKey(const Key('care360-service-workforce')));
    await tester.pump();
    expect(opened, ['Hospitals', 'Workforce']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Services remain usable at 320px with enlarged text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var opened = false;
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(
        size: Size(320, 568),
        textScaler: TextScaler.linear(1.5),
      ),
      child: Scaffold(body: SingleChildScrollView(
        child: Care360PatientServiceGrid(
          onHospitals: () {},
          onPharmacies: () {},
          onDoctors: () {},
          onProviders: () {},
          onLabs: () {},
          onWorkforce: () => opened = true,
        ),
      )),
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('care360-service-workforce')));
    await tester.tap(find.byKey(const Key('care360-service-workforce')));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('All new tiles reuse existing named care routes, Workforce stays protected', () {
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    final grid = File('lib/brand/care360_patient_service_grid.dart').readAsStringSync();
    for (final route in [
      'Hospitals', 'AllPharamacy', 'Treatment', 'Providers', 'Laboratory',
    ]) {
      expect(home, contains("Navigator.pushNamed(context, '$route')"));
    }
    expect(home, contains('Care360PatientServiceGrid('));
    expect(home, contains('const Care360WorkforceLanding()'));
    expect(grid, contains('NeverScrollableScrollPhysics'));
    expect(home, contains('Care360NearbyCareHero('));
    expect(home, contains('Care360PartnerShowcase('));
    expect(home, contains('Care360GuideShortcut()'));
  });
}
