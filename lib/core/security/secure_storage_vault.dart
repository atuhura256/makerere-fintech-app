import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Named key constants for all secure storage entries in the platform.
/// Centralises key strings so there's a single source of truth.
class SecureStorageVault {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Key constants ──────────────────────────────────────────────────────────
  static const String kPhoneKey = 'phone';
  static const String kTenantUuidKey = 'tenant_uuid';
  static const String kSaccoNameKey = 'sacco_name';
  static const String kSchemaNameKey = 'schema_name';
  static const String kUserRoleKey = 'user_role';
  static const String kBearerTokenKey = 'bearer_token';
  static const String kOfflineQueueCipherKey = 'hardware_vault_sacco_cipher_key';

  // ── CRUD helpers ────────────────────────────────────────────────────────────
  static Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  static Future<String?> read(String key) => _storage.read(key: key);

  static Future<void> delete(String key) => _storage.delete(key: key);

  static Future<void> deleteAll() => _storage.deleteAll();

  static Future<bool> containsKey(String key) =>
      _storage.containsKey(key: key);
}
