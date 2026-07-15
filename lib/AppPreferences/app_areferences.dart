import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for anything sensitive: username, password,
/// access token, refresh token. Unlike SharedPreferences (used in
/// AppPreferences for non-sensitive cached data), this is encrypted at rest.
///
/// Add to pubspec.yaml:
///   flutter_secure_storage: ^9.0.0
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage();

  static const _usernameKey = 'saved_username';
  static const _passwordKey = 'saved_password';
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _rememberMeKey = 'remember_me';

  // ── Remember Me flag ──

  static const _dongleIpKey = 'dongle_ip';
  static const _plcIpKey = 'plc_ip';
  static const _plcPortKey = 'plc_port';

static Future<void> saveDongleIp(String? ip) async {
  if (ip == null || ip.isEmpty) return;
  await _storage.write(key: _dongleIpKey, value: ip);

}
static Future<void> savePlcIp(String? ip) async {
  if (ip == null || ip.isEmpty) return;
  await _storage.write(key: _plcIpKey, value: ip);
}

static Future<void> savePlcPort(String? port) async {
  if (port == null || port.isEmpty) return;
  await _storage.write(key: _plcPortKey, value: port);
}


static Future<String?> getDongleIp() async {
  return await _storage.read(key: _dongleIpKey);

}

static Future<String?> getPlcIp() async {
  return await _storage.read(key: _plcIpKey);
}

static Future<String?> getPlcPort() async {
  return await _storage.read(key: _plcPortKey);
}

// ── Full dongle list (PFS stations — multiple dongles, each pre-wired
// to a specific ECU id via ecu_station) — saved as a JSON string at
// login time, read back fresh whenever the PFS screen loads. ──
static const _dongleListKey = 'dongle_list';

static Future<void> saveDongleList(String jsonList) async {
  await _storage.write(key: _dongleListKey, value: jsonList);
}

static Future<String?> getDongleList() async {
  return await _storage.read(key: _dongleListKey);
}

  static Future<void> setRememberMe(bool value) =>
      _storage.write(key: _rememberMeKey, value: value.toString());

  static Future<bool> getRememberMe() async {
    final value = await _storage.read(key: _rememberMeKey);
    return value == 'true';
  }

  // ── Credentials (for pre-filling the login form / optional auto-login) ──

  static Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
  }

  static Future<String?> getSavedUsername() =>
      _storage.read(key: _usernameKey);

  static Future<String?> getSavedPassword() =>
      _storage.read(key: _passwordKey);

  static Future<void> clearCredentials() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }

  // ── Tokens ──

  static Future<void> saveTokens({
    required String? accessToken,
    required String? refreshToken,
  }) async {
    if (accessToken != null) {
      await _storage.write(key: _accessTokenKey, value: accessToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Call on logout.
  static Future<void> clearAll() async {
    await clearCredentials();
    await clearTokens();
    await _storage.delete(key: _rememberMeKey);
  }
}