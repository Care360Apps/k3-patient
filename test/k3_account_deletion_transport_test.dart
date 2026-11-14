import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _DeletionAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(
      '{"success":false,"message":"Synthetic refusal"}',
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('generated account deletion uses POST and preserves server refusal', () async {
    final adapter = _DeletionAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final client = RestClient(dio, baseUrl: 'https://care360.invalid/api/');
    try {
      final result = await client.deleteAccount();
      expect(adapter.request!.method, 'POST');
      expect(adapter.request!.uri.path, '/api/delete-account');
      expect(adapter.request!.queryParameters, isEmpty);
      expect(result.success, isFalse);
    } finally {
      dio.close();
    }
  });
}
