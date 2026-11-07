import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Patient Home does not request storage/location on screen startup', () {
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    expect(home, contains('getLocation();'));
    expect(home, isNot(contains('Permission.storage.request()')));
    expect(home, isNot(contains('Permission.location.request()')));
    expect(home, contains('(await Permission.location.status).isGranted'));
    expect(home, contains('timeout('));
    expect(home, contains('if (mounted) await _getAddress();'));
    expect(home, isNot(contains('    getLiveLocation();')));
  });

  test('appointments polling is canceled and does not run after sign-out', () {
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    expect(home, contains('Timer? _appointmentRefreshTimer;'));
    expect(home, contains('_appointmentRefreshTimer?.cancel();'));
    expect(home, contains('if (!mounted || !_hasAuthToken())'));
    expect(home, contains('_search.dispose();'));
    expect(home, contains('bool _appointmentsInFlight = false'));
    expect(home, contains('if (!mounted || !_hasAuthToken() || _appointmentsInFlight)'));
    expect(home, contains('upcomingAppointment'));
    expect(home, contains('..clear()'));
    expect(home, isNot(contains('upcomingAppointment.addAll(response.data!.upcomingAppointment!)')));
  });

  test('Home never logs personal coordinates, Firebase UID or API error bodies', () {
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    expect(home, isNot(contains('print("UID')));
    expect(home, isNot(contains('Live Location Lat & Long')));
    expect(home, isNot(contains('print("${_locationData.latitude')));
    expect(home, isNot(contains('stackTrace: $stacktrace')));
  });

  test('Dio client uses bounded timeouts but does not automatically retry payments', () {
    final api = File('lib/api/retrofit_Api.dart').readAsStringSync();
    expect(api, contains('connectTimeout = const Duration(seconds: 10)'));
    expect(api, contains('sendTimeout = const Duration(seconds: 20)'));
    expect(api, contains('receiveTimeout = const Duration(seconds: 20)'));
    expect(api, isNot(contains('RetryInterceptor')));
  });
}
