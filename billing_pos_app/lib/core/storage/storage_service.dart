import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:shared_preferences/shared_preferences.dart";

abstract class IStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

class StorageService implements IStorageService {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _sharedPreferences;

  StorageService(this._secureStorage, this._sharedPreferences);

  static Future<StorageService> create() async {
    const secureStorage = FlutterSecureStorage();
    final sharedPrefs = await SharedPreferences.getInstance();
    return StorageService(secureStorage, sharedPrefs);
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {}
    try {
      await _sharedPreferences.setString(key, value);
    } catch (_) {}
  }

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {
      // Fallback to shared_preferences
    }
    try {
      return _sharedPreferences.getString(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
    try {
      await _sharedPreferences.remove(key);
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    try {
      await _sharedPreferences.clear();
    } catch (_) {}
  }
}

