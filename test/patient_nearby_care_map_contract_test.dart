import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Patient map shows doctors, providers and nearby services without fake availability', () {
    final source = File('lib/Screen/Screens/MapView.dart').readAsStringSync();
    expect(source, contains("ChoiceChip("));
    expect(source, contains("'Doctors', 'Providers', 'Hospitals', 'Labs'"));
    expect(source, contains("Key('nearby-filter-"));
    expect(source, contains("'Closest care professionals'"));
    expect(source, contains("Approximate straight-line distance"));
    expect(source, contains("booking times require confirmation"));
    expect(source, contains("ProviderDetail(id: provider.id)"));
    expect(source, contains("DoctorDetail(id: doctor.id)"));
    expect(source, isNot(contains("Available now")));
    expect(source, isNot(contains("Live provider location")));
  });

  test('Patient map uses valid API bounds and respects location permission', () {
    final source = File('lib/Screen/Screens/MapView.dart').readAsStringSync();
    expect(source, contains("'limit': 50"));
    expect(source, isNot(contains("'limit': 100")));
    expect(source, contains("(await Permission.location.status).isGranted"));
    expect(source, contains("myLocationEnabled: _canShowUserLocation"));
    expect(source, contains("if (mounted) setState(() => providerList = list)"));
    expect(source, contains("result.take(8).toList()"));
  });
}
