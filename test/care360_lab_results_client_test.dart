import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../lib/security/care360_lab_results_client.dart';

void main() {
  test(
    'lab result paths are scoped to configured API and include token',
    () async {
      final client = Care360LabResultsClient(
        base: Uri.parse('https://care360.example.test/api/'),
        readToken: () async => 'synthetic-token',
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://care360.example.test/api/patient/lab-results?page=2',
          );
          expect(request.headers['Authorization'], 'Bearer synthetic-token');
          expect(request.followRedirects, isFalse);
          return http.Response(
            jsonEncode({
              'data': {'data': [], 'last_page': 2},
            }),
            200,
          );
        }),
      );
      expect((await client.list(2))['last_page'], 2);
    },
  );
  test('lab client rejects remote cleartext before sending token', () async {
    var sent = false;
    final client = Care360LabResultsClient(
      base: Uri.parse('http://remote.example.test/api/'),
      readToken: () async => 'synthetic-token',
      allowLoopbackHttp: true,
      client: MockClient((r) async {
        sent = true;
        return http.Response('{}', 200);
      }),
    );
    await expectLater(client.list(1), throwsFormatException);
    expect(sent, isFalse);
  });
  test('redirect and non-document responses are rejected', () async {
    for (final status in [302, 200]) {
      final client = Care360LabResultsClient(
        base: Uri.parse('https://care360.example.test/api/'),
        readToken: () async => 'synthetic-token',
        client: MockClient(
          (r) async => http.Response('<html>not a result</html>', status),
        ),
      );
      await expectLater(client.download(10), throwsFormatException);
    }
  });
  test('released PDF bytes can be explicitly saved', () async {
    final client = Care360LabResultsClient(
      base: Uri.parse('https://care360.example.test/api/'),
      readToken: () async => 'synthetic-token',
      client: MockClient(
        (r) async => http.Response('%PDF-1.4 synthetic fixture', 200),
      ),
    );
    final result = await client.download(10);
    expect(result.extension, 'pdf');
    expect(ascii.decode(result.bytes), startsWith('%PDF-'));
  });
}
