import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  // Token management
  static Future<void> saveToken(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      Logger.info('Token saved securely: $key');
    } catch (e) {
      Logger.error('Save token error: $e');
      rethrow;
    }
  }

  static Future<String?> getToken(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      Logger.error('Get token error: $e');
      return null;
    }
  }

  static Future<void> deleteToken(String key) async {
    try {
      await _storage.delete(key: key);
      Logger.info('Token deleted: $key');
    } catch (e) {
      Logger.error('Delete token error: $e');
      rethrow;
    }
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      Logger.info('All secure storage cleared');
    } catch (e) {
      Logger.error('Clear storage error: $e');
      rethrow;
    }
  }

  // Auth tokens
  static Future<void> saveAccessToken(String token) async {
    await saveToken('access_token', token);
  }

  static Future<String?> getAccessToken() async {
    return getToken('access_token');
  }

  static Future<void> saveRefreshToken(String token) async {
    await saveToken('refresh_token', token);
  }

  static Future<String?> getRefreshToken() async {
    return getToken('refresh_token');
  }

  static Future<void> saveUserId(String userId) async {
    await saveToken('user_id', userId);
  }

  static Future<String?> getUserId() async {
    return getToken('user_id');
  }

  // Sensitive data
  static Future<void> saveDuressPin(String pin) async {
    await saveToken('duress_pin', pin);
  }

  static Future<String?> getDuressPin() async {
    return getToken('duress_pin');
  }

  static Future<void> clearAuthTokens() async {
    try {
      await deleteToken('access_token');
      await deleteToken('refresh_token');
      await deleteToken('user_id');
      Logger.info('Auth tokens cleared');
    } catch (e) {
      Logger.error('Clear auth tokens error: $e');
      rethrow;
    }
  }
}
