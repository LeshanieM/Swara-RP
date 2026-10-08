import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    for (final key in [AppConstants.tokenKey, AppConstants.userKey]) {
      final legacyValue = _prefs?.getString(key);
      if (legacyValue != null) {
        await _secureStorage.write(key: key, value: legacyValue);
        await _prefs?.remove(key);
      }
    }
  }

  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return _secureStorage.read(key: AppConstants.tokenKey);
  }

  static Future<void> removeToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  static Future<void> saveString(String key, String value) async {
    if (key == AppConstants.userKey) {
      await _secureStorage.write(key: key, value: value);
      return;
    }
    await _prefs?.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    if (key == AppConstants.userKey) {
      return _secureStorage.read(key: key);
    }
    return _prefs?.getString(key);
  }

  static Future<void> remove(String key) async {
    if (key == AppConstants.userKey) {
      await _secureStorage.delete(key: key);
      return;
    }
    await _prefs?.remove(key);
  }

  static Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    return _prefs?.getBool(key);
  }

  static Future<void> clearAll() async {
    await _prefs?.clear();
    await _secureStorage.deleteAll();
  }

  static bool isDemoMode() {
    return _prefs?.getBool(AppConstants.demoModeKey) ?? false;
  }

  static Future<void> setDemoMode(bool value) async {
    await _prefs?.setBool(AppConstants.demoModeKey, value);
  }
}
