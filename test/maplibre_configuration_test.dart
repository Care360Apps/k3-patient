import 'package:flutter_test/flutter_test.dart';
import '../lib/nearby/maplibre_configuration.dart';

void main() {
  test('requires HTTPS and attribution', () {
    expect(MapLibreConfiguration.isValid('https://maps.example.org/style.json', 'Map data'), isTrue);
    expect(MapLibreConfiguration.isValid('http://maps.example.org/style.json', 'Map data'), isFalse);
    expect(MapLibreConfiguration.isValid('', 'Map data'), isFalse);
    expect(MapLibreConfiguration.isValid('https://maps.example.org/style.json', ' '), isFalse);
    expect(MapLibreConfiguration.isValid('https://user:pass@maps.example.org/style.json', 'Map data'), isFalse);
    expect(MapLibreConfiguration.isValid('https:///style.json', 'Map data'), isFalse);
  });
}
