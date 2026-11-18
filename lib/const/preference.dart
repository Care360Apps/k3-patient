import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static SharedPreferences _preferences = _preferences;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  );

  /// Keys that must never be written to SharedPreferences in cleartext.
  static const List<String> _secureKeys = [Preferences.auth_token];

  /// Secure values are mirrored in memory so they can be read synchronously and survive a failing keystore for the
  /// lifetime of the process without falling back to cleartext storage.
  static final Map<String, String> _secureCache = {};

  static Future init({bool offlineSandbox = false}) async {
    _preferences = await SharedPreferences.getInstance();
    // One-time removal of a legacy cleartext Firebase password from old installs.
    await _preferences.remove(FirestoreConstants.password);
    if (offlineSandbox) {
      // Only for the distinct .k3sandbox debug application; no credential
      // migration or Android Keystore access is needed in a design preview.
      _secureCache.clear();
      await _preferences.remove(Preferences.auth_token);
      return;
    }
    for (final key in _secureKeys) {
      await _loadSecure(key);
    }
  }

  static Future<void> _loadSecure(String key) async {
    String? value;
    try {
      value = await _secureStorage.read(key: key);
    } catch (_) {}
    final legacy = _preferences.getString(key);
    if (_isBlank(value) && !_isBlank(legacy)) {
      value = legacy!.trim();
      try {
        await _secureStorage.write(key: key, value: value);
      } catch (_) {}
    }
    if (legacy != null) {
      await _preferences.remove(key);
    }
    if (!_isBlank(value)) {
      _secureCache[key] = value!.trim();
    }
  }

  static bool _isBlank(String? v) => v == null || v.trim().isEmpty || v == "N_A" || v == "null";

  static Future setString(String key, String value) async {
    if (key == FirestoreConstants.password) {
      throw StateError('Storing a password in SharedPreferences is prohibited.');
    }
    return await _preferences.setString(key, value);
  }

  static String? getString(String key) => _preferences.getString(key) ?? "N_A";

  static Future setBoolean(String key, bool value) async => await _preferences.setBool(key, value);

  static bool getBoolean(String key) => _preferences.getBool(key) ?? false;

  static int getInt(dynamic key) {
    return _preferences.getInt("$key") ?? 0;
  }

  static Future setInt(String key, int value) async {
    return await _preferences.setInt("$key", value);
  }

  static Future<void> clearPref() async {
    // Do not race account logout/deletion navigation with disk persistence.
    await _preferences.clear();
  }

  static Future setSecureString(String key, String value) async {
    final trimmed = value.trim();
    _secureCache[key] = trimmed;
    try {
      await _secureStorage.write(key: key, value: trimmed);
    } catch (_) {}
    await _preferences.remove(key);
  }

  static Future<String?> getSecureString(String key) async {
    final cached = _secureCache[key];
    if (!_isBlank(cached)) {
      return cached;
    }
    try {
      final secureValue = await _secureStorage.read(key: key);
      if (!_isBlank(secureValue)) {
        _secureCache[key] = secureValue!.trim();
        return _secureCache[key];
      }
    } catch (_) {}
    return null;
  }

  /// Synchronous read of a secure value loaded during [init] or set since.
  static String? peekSecureString(String key) {
    final cached = _secureCache[key];
    return _isBlank(cached) ? null : cached;
  }

  static Future deleteSecureString(String key) async {
    _secureCache.remove(key);
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
    await _preferences.remove(key);
  }

  static Future clearSecure() async {
    _secureCache.clear();
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }
}
