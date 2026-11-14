import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Only constructs paths under the configured clinical API. Never follows redirects.
class Care360LabResultsClient {
  Care360LabResultsClient({
    required this.base,
    required this.readToken,
    http.Client? client,
    this.allowLoopbackHttp = false,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;
  final Uri base;
  final Future<String?> Function() readToken;
  final bool allowLoopbackHttp;
  final http.Client _client;
  final bool _ownsClient;
  void close() {
    if (_ownsClient) _client.close();
  }

  Future<http.StreamedResponse> _get(String path, String accept) async {
    final local = ['localhost', '127.0.0.1', '::1'].contains(base.host);
    if (base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        base.path != '/api/' ||
        (base.scheme != 'https' &&
            !(allowLoopbackHttp && local && base.scheme == 'http')))
      throw const FormatException('Secure Care360 connection required.');
    final token = (await readToken())?.trim();
    if (token == null || token.isEmpty || token == 'N_A' || token == 'null')
      throw const FormatException('Sign in to see your laboratory results.');
    final request = http.Request('GET', base.resolve(path))
      ..followRedirects = false
      ..headers.addAll({'Accept': accept, 'Authorization': 'Bearer $token'});
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      await response.stream.drain<void>();
      throw const FormatException(
        'Results unavailable. Please refresh or contact your laboratory.',
      );
    }
    return response;
  }

  Future<Uint8List> _bounded(http.StreamedResponse response, int limit) async {
    if ((response.contentLength ?? 0) > limit) {
      await response.stream.drain<void>();
      throw const FormatException('Result file is too large.');
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 20),
    )) {
      bytes.add(chunk);
      if (bytes.length > limit)
        throw const FormatException('Result file is too large.');
    }
    return bytes.takeBytes();
  }

  Future<Map<String, dynamic>> list(int page) async {
    if (page < 1) throw const FormatException('Invalid page.');
    final response = await _get(
      'patient/lab-results?page=$page',
      'application/json',
    );
    final body = jsonDecode(utf8.decode(await _bounded(response, 512 * 1024)));
    if (body is! Map || body['data'] is! Map)
      throw const FormatException('Invalid result response.');
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  Future<({Uint8List bytes, String extension})> download(int id) async {
    if (id < 1) throw const FormatException('Invalid laboratory booking.');
    final response = await _get(
      'patient/lab-results/$id/file',
      'application/pdf,image/jpeg,image/png',
    );
    final bytes = await _bounded(response, 10 * 1024 * 1024);
    final pdf =
        bytes.length >= 5 &&
        ascii.decode(bytes.sublist(0, 5), allowInvalid: true) == '%PDF-';
    final png =
        bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71 &&
        bytes[4] == 13 &&
        bytes[5] == 10 &&
        bytes[6] == 26 &&
        bytes[7] == 10;
    final jpg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (!pdf && !png && !jpg)
      throw const FormatException('Unsupported result document.');
    return (
      bytes: bytes,
      extension: pdf
          ? 'pdf'
          : png
          ? 'png'
          : 'jpg',
    );
  }
}
