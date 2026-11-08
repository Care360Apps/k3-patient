import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:doctro_patient/security/care360_medical_pdf_client.dart';

void main() {
  final base = Uri.parse('https://api.example.test/api/');
  const validPdf = '%PDF-1.4\n% test document';

  test('Authenticated medical PDF uses same-origin, nonredirecting GET', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.followRedirects, isFalse);
      expect(request.url.toString(),
          'https://api.example.test/api/medical-files/appointments/12/prescription');
      expect(request.headers['Authorization'], 'Bearer synthetic-token');
      return http.Response(validPdf, 200, headers: {
        'content-type': 'application/pdf',
      });
    });
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: client,
      readToken: () async => 'synthetic-token',
    );
    final bytes = await service.fetchForAppointment(12,
      serverPdfUrl:
          'https://api.example.test/api/medical-files/appointments/12/prescription');
    expect(String.fromCharCodes(bytes), validPdf);
    service.close();
  });

  test('Legacy PDF only from same host, never receives Authorization', () async {
    final client = MockClient((request) async {
      expect(request.url.path,
          '/prescription/upload/0123456789abcdef0123456789abcdef.pdf');
      expect(request.headers.containsKey('Authorization'), isFalse);
      return http.Response(validPdf, 200,
        headers: {'content-type': 'application/pdf'});
    });
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: client,
      readToken: () async => 'synthetic-token',
    );
    await service.fetchForAppointment(12, serverPdfUrl:
      'https://api.example.test/prescription/upload/0123456789abcdef0123456789abcdef.pdf');
  });

  test('Foreign host, tampered path and HTTP are rejected before request', () async {
    var calls = 0;
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: MockClient((_) async {
        calls++;
        return http.Response(validPdf, 200);
      }),
      readToken: () async => 'synthetic-token',
    );
    for (final link in [
      'https://malicious.example/prescription/upload/0123456789abcdef.pdf',
      'http://api.example.test/prescription/upload/0123456789abcdef.pdf',
      'https://api.example.test/other/file.pdf',
      'https://api.example.test/prescription/upload/../../secret.pdf',
      'https://api.example.test/prescription/upload/0123456789abcdef.pdf?token=abc'
    ]) {
      await expectLater(service.fetchForAppointment(12, serverPdfUrl: link),
          throwsFormatException);
    }
    expect(calls, 0);
  });

  test('Private PDF requires a real login token', () async {
    final service = Care360MedicalPdfClient(
      apiBase: base,
      httpClient: MockClient((_) async => http.Response(validPdf, 200)),
      readToken: () async => null,
    );
    await expectLater(service.fetchForAppointment(12, serverPdfUrl:
      'https://api.example.test/api/medical-files/appointments/12/prescription'),
      throwsA(isA<MedicalPdfException>()));
  });

  test('HTTP redirect, error payload, non-PDF and network failure never save data', () async {
    for (final response in [
      http.Response('', 302, headers: {'location':'https://other.example/'}),
      http.Response('{"error":"not found"}', 404,
        headers: {'content-type':'application/json'}),
      http.Response('error', 200, headers: {'content-type':'text/html'}),
      http.Response('not a pdf', 200,
        headers: {'content-type':'application/pdf'}),
    ]) {
      final service = Care360MedicalPdfClient(
        apiBase: base,
        httpClient: MockClient((_) async => response),
        readToken: () async => 'synthetic-token',
      );
      await expectLater(service.fetchForAppointment(12,
        serverPdfUrl:
          'https://api.example.test/api/medical-files/appointments/12/prescription'),
        throwsA(isA<MedicalPdfException>()));
    }
  });

  test('No plaintext HTTP medical files in production mode', () async {
    final service = Care360MedicalPdfClient(
      apiBase: Uri.parse('http://127.0.0.1:8021/api/'),
      httpClient: MockClient((_) async =>
          http.Response(validPdf, 200, headers: {'content-type':'application/pdf'})),
      readToken: () async => 'synthetic-token',
    );
    await expectLater(service.fetchForAppointment(12,
      serverPdfUrl:'http://127.0.0.1:8021/api/medical-files/appointments/12/prescription'),
      throwsA(isA<MedicalPdfException>()));
  });

  test('Patient download screens use the bounded client and user-directed save',
      () {
    for (final file in [
      'lib/Screen/MedicineAndPharmacy/Myprescription.dart',
      'lib/Screen/AppointmentRelatedScreen/AppointmentDetailScreen.dart',
    ]) {
      final source = File(file).readAsStringSync();
      expect(source, contains('Care360MedicalPdfClient('));
      expect(source, contains('FilePicker.platform.saveFile('));
      expect(source, contains('Preferences.auth_token'));
      expect(source, contains('SharedPreferenceHelper.getSecureString'));
      expect(source, isNot(contains('Permission.storage.request()')));
      expect(source, isNot(contains('HttpClient.getUrl(')));
    }
  });
}
