import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/Screen/Location/care360_place_search.dart';

Dio syntheticDio({bool offline = false}) {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    if (offline) {
      return handler.reject(DioException(
        requestOptions: options, type: DioExceptionType.connectionError));
    }
    if (options.path.endsWith('places/autocomplete')) {
      return handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: {
          'success': true,
          'data': [{'place_id': 'ChIJTestPlaceKeffi123',
                    'description': 'Synthetic Clinic, Keffi'}],
        },
      ));
    }
    if (options.path.endsWith('places/details')) {
      return handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: {
          'success': true,
          'data': {'address': 'Synthetic Clinic, Keffi, Nigeria',
                   'latitude': 8.846, 'longitude': 7.873},
        },
      ));
    }
    handler.reject(DioException(
      requestOptions: options, type: DioExceptionType.badResponse));
  }));
  return dio;
}

void main() {
  test('Authenticated Places gateway normalizes suggestions and coordinates',
      () async {
    final gateway = Care360PlacesGateway(dio: syntheticDio());
    const session = 'b7ae47c8-8a7f-42e4-841d-6a9a78801945';
    final places = await gateway.search('Synthetic Clinic Keffi', session);
    expect(places, hasLength(1));
    expect(places.single.id, 'ChIJTestPlaceKeffi123');
    final selected = await gateway.resolve(places.single.id, session);
    expect(selected.address, 'Synthetic Clinic, Keffi, Nigeria');
    expect(selected.latitude, closeTo(8.846, 0.00001));
    expect(selected.longitude, closeTo(7.873, 0.00001));
  });

  testWidgets('Places search failure offers manual map selection without crash',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Care360PlaceSearchSheet(
            gateway: Care360PlacesGateway(dio: syntheticDio(offline: true)),
          ),
        ),
      ),
    ));
    await tester.enterText(
        find.byKey(const Key('care360-place-query')), 'Keffi hospital');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(find.textContaining('Search unavailable'), findsOneWidget);
    expect(find.text('Select manually on map'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
