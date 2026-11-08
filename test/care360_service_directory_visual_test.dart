import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_service_intro.dart';

void main() {
  testWidgets('Care360 healthcare directory heading is accessible and branded',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Care360ServiceIntro(
        title: 'Hospitals',
        description: 'Explore healthcare facilities',
        icon: Icons.local_hospital_outlined,
      )),
    ));
    expect(find.text('Hospitals'), findsOneWidget);
    expect(find.text('Explore healthcare facilities'), findsOneWidget);
    expect(find.byKey(const Key('care360-service-intro')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Directory headings fit 320px and larger text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: MediaQuery(
      data: MediaQueryData(size: Size(320, 568),
          textScaler: TextScaler.linear(1.6)),
      child: Scaffold(body: SafeArea(child: Care360ServiceIntro(
        title: 'Laboratories',
        description: 'Search labs and available tests',
        icon: Icons.biotech_outlined,
      ))),
    )));
    expect(find.text('Laboratories'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Hospital navigation reaches existing live searchable directory, not placeholder', () {
    final routes = File('lib/main.dart').readAsStringSync();
    final hospitalStub = File('lib/Screen/Screens/HospitalsScreen.dart')
        .readAsStringSync();
    final realDirectory = File('lib/Screen/Screens/Laboratory.dart')
        .readAsStringSync();
    expect(routes, contains("'Hospitals': (context) => HospitalScreen()"));
    expect(routes, isNot(contains("'Hospitals': (context) => HospitalsScreen()")));
    expect(hospitalStub, contains("child: Text('Find Hospitals')"));
    expect(realDirectory, contains('class HospitalScreen extends StatefulWidget'));
    expect(realDirectory, contains('hospitalsRequest()'));
    expect(realDirectory, contains('Care360ServiceIntro('));
    expect(realDirectory, contains("title: 'Hospitals'"));
    expect(realDirectory, contains("title: 'Laboratories'"));
  });

  test('All four other directories retain original APIs and navigation', () {
    final files = <String, List<String>>{
      'lib/Screen/Doctor/Treatment.dart': [
        'Care360ServiceIntro(',
        'treatmentsRequest()',
        'TreatmentSpecialist(',
      ],
      'lib/Screen/Provider/FindProvidersScreen.dart': [
        'Care360ServiceIntro(',
        'callApiProviders',
        'ProviderDiscoveryFilter',
      ],
      'lib/Screen/MedicineAndPharmacy/AllPharamacy.dart': [
        'Care360ServiceIntro(',
        'pharmacysRequest()', 
        'PharamacyDetail(',
      ],
    };
    for (final entry in files.entries) {
      final code = File(entry.key).readAsStringSync();
      for (final expected in entry.value) {
        expect(code, contains(expected), reason: entry.key);
      }
    }
  });
}
