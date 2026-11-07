import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Add Address supports manual map selection without Places key', () {
    final add = File('lib/Screen/Location/AddLocation.dart').readAsStringSync();

    // A valid Maps SDK map must remain useful when separate legacy
    // Places REST search is disabled or lacks a key.
    expect(add, contains('onTap: _selectPointOnMap'));
    expect(add, contains('void _selectPointOnMap(LatLng point)'));
    expect(add, contains('selectLat = point.latitude'));
    expect(add, contains('selectLang = point.longitude'));
    expect(add, contains('_initialCameraPosition = point'));
    expect(add, contains('Location selected. Enter the address'));
    expect(add, contains('Search unavailable. Tap the map'));
    expect(add, contains('if (selectLat != 0.0 && selectLang != 0.0)'));
    expect(add, contains('callApiAddAddress()'));
  });

  test('Manual address entry accepts spaces and African Unicode text', () {
    final add = File('lib/Screen/Location/AddLocation.dart').readAsStringSync();

    // Input should not discard spaces, slashes or diacritics from addresses.
    expect(add, isNot(contains("RegExp('[a-zA-Z0-9]')")));
    expect(add, isNot(contains("RegExp('[a-zA-Z0-9,]')")));
    expect(add, contains('value.trim().isEmpty'));
  });

  test('No backend or Google credential is embedded as a fallback', () {
    final add = File('lib/Screen/Location/AddLocation.dart').readAsStringSync();

    expect(add, contains('Preferences.map_key'));
    expect(add, isNot(contains("AIza")));
    expect(add, isNot(contains('K3_STAGING_MAPS_ANDROID_API_KEY')));
    expect(add, isNot(contains('http://maps.googleapis.com')));
  });
}
