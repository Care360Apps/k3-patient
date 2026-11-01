import 'package:dio/dio.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Patient login uses the expected API contract without any real HTTP call', () async {
    String? route;
    String? method;
    Map<String, dynamic>? payload;
    final dio = Dio()..interceptors.add(InterceptorsWrapper(
      onRequest: (request, handler) {
        route = request.uri.path;
        method = request.method;
        payload = Map<String, dynamic>.from(request.data as Map);
        handler.resolve(Response(
          requestOptions: request,
          statusCode: 200,
          data: {'success': true, 'msg': 'Synthetic contract OK', 'data': {
            'id': 1001, 'name': 'Synthetic Patient', 'email': 'patient@example.test',
            'verify': 1, 'token': 'not-a-real-session-token',
            'firebase_custom_token': null,
          }},
        ));
      },
    ));
    final response = await RestClient(dio, baseUrl: 'https://staging.example.test/api/')
        .loginRequest({'email': 'patient@example.test', 'password': 'synthetic-secret'});
    expect(route, '/api/login');
    expect(method, 'POST');
    expect(payload?['email'], 'patient@example.test');
    expect(payload?['password'], 'synthetic-secret');
    expect(response.success, isTrue);
    expect(response.data?.id, 1001);
    expect(response.data?.verify, 1);
  });
}
