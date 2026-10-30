import 'package:dio/dio.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/api/network_api.dart';

class RetroApi {
  Dio dioData() {
    return _ApiDio.authDio();
  }
}

class RetroApi2 {
  Dio dioData2() {
    return _ApiDio.noAuthDio();
  }
}

class _ApiDio {
  static Dio? _dioAuth;
  static Dio? _dioNoAuth;
  static Future<String?>? _refreshingToken;

  static Dio authDio() {
    if (_dioAuth != null) {
      return _dioAuth!;
    }
    final dio = _buildBase();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SharedPreferenceHelper.getSecureString(Preferences.auth_token);
          final hadToken = token != null &&
              token.isNotEmpty &&
              token != "N_A" &&
              token != "null";
          if (hadToken) {
            options.headers["Authorization"] = "Bearer ${token.trim()}";
            options.extra['auth_token_attached'] = true;
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final sentToken = error.requestOptions.extra['auth_token_attached'] == true;
            final alreadyRetried = error.requestOptions.extra['retry'] == true;
            if (!sentToken) {
              return handler.next(error);
            }
            if (alreadyRetried) {
              await _clearAuthState();
              return handler.next(error);
            }
            final token = await SharedPreferenceHelper.getSecureString(Preferences.auth_token);
            if (token == null || token.isEmpty || token == "N_A" || token == "null") {
              await _clearAuthState();
              return handler.next(error);
            }
            _refreshingToken ??= _refreshToken(token);
            final newToken = await _refreshingToken;
            _refreshingToken = null;
            if (newToken == null || newToken.isEmpty || newToken == "N_A" || newToken == "null") {
              await _clearAuthState();
              return handler.next(error);
            }
            await SharedPreferenceHelper.setSecureString(Preferences.auth_token, newToken);
            await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, true);
            await SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
            final requestOptions = error.requestOptions;
            requestOptions.extra['retry'] = true;
            requestOptions.headers["Authorization"] = "Bearer $newToken";
            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          }
          handler.next(error);
        },
      ),
    );
    _dioAuth = dio;
    return dio;
  }

  static Dio noAuthDio() {
    if (_dioNoAuth != null) {
      return _dioNoAuth!;
    }
    _dioNoAuth = _buildBase();
    return _dioNoAuth!;
  }

  static Dio _buildBase() {
    final dio = Dio();
    dio.options.headers["Accept"] = "application/json";
    dio.options.followRedirects = false;
    dio.options.connectTimeout = Duration(seconds: 30);
    dio.options.receiveTimeout = Duration(seconds: 30);
    return dio;
  }

  static Future<void> _clearAuthState() async {
    await SharedPreferenceHelper.deleteSecureString(Preferences.auth_token);
    await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, false);
    await SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, false);
  }

  static Future<String?> _refreshToken(String token) async {
    try {
      final refreshDio = _buildBase();
      refreshDio.options.headers["Authorization"] = "Bearer $token";
      final response = await RestClient(refreshDio).refreshToken();
      final newToken = response.data?.token;
      if (response.success == true && newToken != null && newToken.isNotEmpty && newToken != "null") {
        return newToken;
      }
    } catch (_) {}
    return null;
  }
}
