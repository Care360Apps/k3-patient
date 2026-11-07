import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/apis.dart';

/// The Workforce API uses a *separate* 64-character opaque session token.
/// Do not reuse Retrofit/Patient OAuth interceptors or clinical Firestore chat.
class WorkforceApi {
  WorkforceApi({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(
            baseUrl: Apis.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            followRedirects: false,
            headers: const {'Accept': 'application/json'},
          )),
        _storage = storage ?? const FlutterSecureStorage();

  static const tokenKey = 'care360_workforce_session';
  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<bool> applicationsOpen() async {
    try {
      final response = await _dio.get('workforce/v1/status');
      final data = _body(response)['data'];
      return data is Map && data['applications_open'] == true;
    } catch (_) {
      return false; // Network uncertainty never opens registrations.
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String accountType,
    required bool adultAttestation,
    required bool acceptedTerms,
  }) async {
    await _request('post', 'workforce/v1/register', body: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'password_confirmation': password,
      'account_type': accountType,
      'adult_attestation': adultAttestation,
      'workforce_terms_accepted': acceptedTerms,
    }, authenticated: false);
  }

  Future<String> login(String email, String password) async {
    final result = await _request('post', 'workforce/v1/login',
        body: {'email': email.trim().toLowerCase(), 'password': password},
        authenticated: false);
    final data = result['data'];
    final token = data is Map ? data['token'] : null;
    final role = data is Map ? data['role'] : null;
    if (token is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{60,70}$').hasMatch(token) ||
        (role != 'candidate' && role != 'employer')) {
      throw const FormatException('Workforce login response is invalid.');
    }
    await _storage.write(key: tokenKey, value: token);
    return role as String;
  }

  Future<Map<String, dynamic>> me() async {
    final result = await _request('get', 'workforce/v1/me');
    final data = result['data'];
    if (data is! Map) throw const FormatException('Invalid Workforce profile.');
    return Map<String, dynamic>.from(data);
  }

  Future<void> saveCandidate(Map<String, dynamic> profile) async {
    await _request('post', 'workforce/v1/candidate/profile', body: profile);
  }

  Future<void> saveEmployer(Map<String, dynamic> profile) async {
    await _request('post', 'workforce/v1/employer/profile', body: profile);
  }

  Future<List<Map<String, dynamic>>> searchCandidates(
      {String? state, String? desiredRole}) async {
    final result = await _request('get', 'workforce/v1/candidates',
        query: {
          if (state != null && state.isNotEmpty) 'state': state,
          if (desiredRole != null && desiredRole.isNotEmpty)
            'desired_role': desiredRole,
        });
    final data = result['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((row) =>
        Map<String, dynamic>.from(row)).toList(growable: false);
  }

  Future<void> logout() async {
    try {
      await _request('post', 'workforce/v1/logout');
    } finally {
      await _storage.delete(key: tokenKey);
    }
  }

  Future<Map<String, dynamic>> _request(
      String method, String path, {
      Map<String, dynamic>? body,
      Map<String, dynamic>? query,
      bool authenticated = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (authenticated) {
      final token = await _storage.read(key: tokenKey);
      if (token == null || token.isEmpty) {
        throw const WorkforceApiException('Sign in to Workforce first.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final response = await _dio.request<dynamic>(path,
          options: Options(method: method.toUpperCase(), headers: headers),
          data: body, queryParameters: query);
      final result = _body(response);
      if (result['success'] != true) {
        throw const WorkforceApiException('Request could not be completed.');
      }
      return result;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const WorkforceApiException(
            'Your Workforce session has expired. Sign in again.');
      }
      if (error.response?.statusCode == 403) {
        throw const WorkforceApiException(
            'Organization approval is required to access this area.');
      }
      if (error.response?.statusCode == 503) {
        throw const WorkforceApiException(
            'Workforce pilot is not accepting requests yet.');
      }
      throw const WorkforceApiException(
          'Connection unavailable. Please try again.');
    }
  }

  Map<String, dynamic> _body(Response<dynamic> response) {
    final value = response.data;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Unexpected Workforce response.');
  }
}

class WorkforceApiException implements Exception {
  const WorkforceApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
