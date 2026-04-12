import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu SĐT (SharedPreferences) + mật khẩu (Keychain/Keystore) khi người dùng bật ghi nhớ.
class CredentialStore {
  CredentialStore._();

  static const _kRemember = 'bvc_remember_credentials';
  static const _kPhone = 'bvc_saved_phone';
  static const _kSecurePassword = 'bvc_saved_password';

  static final FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
    iOptions: const IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static Future<bool> getRememberDefault() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kRemember) ?? true;
  }

  static Future<void> setRemember(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kRemember, value);
  }

  /// Ghi nhớ SĐT + mật khẩu (mật khẩu chỉ trên secure storage).
  static Future<void> save({required String normalizedPhone, required String password}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPhone, normalizedPhone);
    await _secure.write(key: _kSecurePassword, value: password);
    await sp.setBool(_kRemember, true);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kPhone);
    await sp.setBool(_kRemember, false);
    await _secure.delete(key: _kSecurePassword);
  }

  static Future<({String? phone, String? password})> loadIfRemembered() async {
    final sp = await SharedPreferences.getInstance();
    final remember = sp.getBool(_kRemember) ?? true;
    if (!remember) return (phone: null, password: null);
    final phone = sp.getString(_kPhone);
    final password = await _secure.read(key: _kSecurePassword);
    return (phone: phone, password: password);
  }
}
