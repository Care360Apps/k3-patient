import 'dart:io';

import 'package:doctro_patient/nearby/nearby_on_duty_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final valid = <String, dynamic>{
    'id': 12,
    'name': 'Approved professional',
    'role': 'provider',
    'lat': 8.86,
    'lng': 7.87,
    'distance_km': 1.6,
    'accepting_requests': true,
    'on_duty_until': DateTime.now().toUtc()
        .add(const Duration(hours: 1)).toIso8601String(),
  };

  test('accepts a bounded published-area response without medical information', () {
    final p = NearbyOnDutyProfessional.fromJson(valid);
    expect(p, isNotNull);
    expect(p!.id, 12);
    expect(p.role, 'provider');
    expect(p.distanceKm, 1.6);
    expect(p.isStillAccepting, isTrue);
  });

  test('rejects unconfirmed, malformed or inappropriate professional records', () {
    for (final change in [
      {'accepting_requests': false},
      {'id': 0},
      {'name': ''},
      {'role': 'admin'},
      {'lat': 190},
      {'lng': 194},
      {'distance_km': -1},
      {'distance_km': double.nan},
      {'on_duty_until': 'not-a-date'},
      {'on_duty_until': DateTime.now().toUtc()
          .subtract(const Duration(minutes: 1)).toIso8601String()},
    ]) {
      expect(NearbyOnDutyProfessional.fromJson({...valid, ...change}), isNull);
    }
    expect(NearbyOnDutyProfessional.fromJson(null), isNull);
  });

  test('source only queries confirmed availability on user action', () {
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    final map = File('lib/Screen/Screens/MapView.dart').readAsStringSync();
    final service = File('lib/nearby/nearby_on_duty_service.dart').readAsStringSync();
    expect(home, contains("Key('home-find-nearby-care')"));
    expect(home, contains("Navigator.pushNamed(context, 'MapView')"));
    expect(map, contains("Key('nearby-on-duty-filter')"));
    expect(map, contains("Key('nearby-service-\$key')"));
    expect(map, contains("Home visits"));
    expect(map, contains("Virtual care"));
    expect(map, contains("visitType: _selectedVisitType"));
    expect(service, contains("'visit_type': visitType"));
    expect(map, contains('Future<void> _toggleOnDuty(bool enabled) async'));
    expect(map, contains("if (enabled) await _fetchOnDuty()"));
    expect(map, contains('Accepting requests'));
    expect(map, contains("The verified availability service is not enabled"));
    expect(service, contains("base.scheme != 'https'"));
    expect(service, contains("base.resolve('nearby-care')"));
    expect(service, contains("'radius_km': radiusKm.clamp(1, 50)"));
    expect(service, isNot(contains('patientMedicalHistory')));
    expect(map, isNot(contains('Live tracking enabled')));
  });
}
