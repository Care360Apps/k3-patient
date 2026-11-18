import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_patient_service_grid.dart';

void main() {
  testWidgets('Healthcare discovery uses six working, role-safe callbacks',
      (tester) async {
    final opened = <Care360ServiceDestination>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Care360PatientServiceGrid(onOpen: opened.add),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Explore healthcare'), findsOneWidget);
    expect(find.byKey(const Key('care360-services-grid')), findsOneWidget);
    for (final destination in Care360ServiceDestination.values) {
      final key = Key('care360-service-${destination.name}');
      await tester.ensureVisible(find.byKey(key));
      await tester.tap(find.byKey(key));
    }
    expect(opened, Care360ServiceDestination.values);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Grid stays readable on 320px device with large fonts',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.6),
        ),
        child: Scaffold(body: SingleChildScrollView(
          child: Care360PatientServiceGrid(onOpen: (_) {}),
        )),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(
        const Key('care360-service-appointments')));
    expect(tester.takeException(), isNull);
  });

  test('Home retains old services, real appointments and sponsored section', () {
    final source = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    expect(source, contains('Care360PatientServiceGrid('));
    expect(source, contains('Care360NearbyCareHero('));
    expect(source, contains('Care360WorkforceHomeTile('));
    expect(source, contains('Care360PartnerShowcase('));
    expect(source, contains('Care360GuideShortcut('));
    expect(source, contains('upcomingAppointment'));
    for (final route in [
      "'Hospitals'", "'Treatment'", "'FindProviders'",
      "'AllPharamacy'", "'Laboratory'", "'Appointment'",
    ]) {
      expect(source, contains('Navigator.pushNamed('));
      expect(source, contains(route));
    }
    expect(source, contains("_hasAuthToken() ? 'Appointment' : 'SignIn'"));
    expect(source, isNot(contains('Permission.location.request()')));
    expect(source, isNot(contains('Permission.storage.request()')));
  });
}
