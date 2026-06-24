import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:makerere_fintech_app/core/security/secure_storage_vault.dart';

/// Hardware-encrypted local offline queue for pending SACCO transactions.
///
/// Transactions are serialised to JSON strings and stored in an AES-encrypted
/// Hive box. The AES key is derived once and persisted in the device hardware
/// keystore / keychain via [SecureStorageVault].
///
/// This fulfils Section 3B of the SKILLS_FRONTEND.md blueprint, providing a
/// durable, offline-safe staging area before payloads are flushed to Supabase.
class SecureOfflineQueueManager {
  static const String _queueBoxName = 'encrypted_tx_queue_payloads';

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Opens (or creates) the encrypted Hive box, generating the AES key on
  /// first run and storing it in the secure hardware keystore.
  static Future<Box<String>> _getSecureChannel() async {
    String? base64Key =
        await SecureStorageVault.read(SecureStorageVault.kOfflineQueueCipherKey);

    if (base64Key == null) {
      final List<int> generatedKey = Hive.generateSecureKey();
      base64Key = base64Encode(generatedKey);
      await SecureStorageVault.write(
        SecureStorageVault.kOfflineQueueCipherKey,
        base64Key,
      );
    }

    final List<int> decryptionKey = base64Decode(base64Key);
    return Hive.openBox<String>(
      _queueBoxName,
      encryptionCipher: HiveAesCipher(decryptionKey),
    );
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Stages [payload] (already serialised to a Map via `toSupabasePayload()`)
  /// into the encrypted local queue for deferred syncing.
  static Future<void> stageTransactionToQueue(Map<String, dynamic> payload) async {
    final box = await _getSecureChannel();
    final stringifiedPayload = jsonEncode(payload);
    await box.add(stringifiedPayload);
  }

  /// Returns all pending payloads as a list of decoded Maps.
  static Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final box = await _getSecureChannel();
    return box.values
        .map((raw) => jsonDecode(raw) as Map<String, dynamic>)
        .toList();
  }

  /// Removes the entry at [boxKey] from the queue (call after successful sync).
  static Future<void> dequeueTransaction(int boxKey) async {
    final box = await _getSecureChannel();
    await box.delete(boxKey);
  }

  /// Returns the number of transactions currently staged in the local queue.
  static Future<int> getPendingCount() async {
    final box = await _getSecureChannel();
    return box.length;
  }

  /// Clears all pending transactions (use with caution in production).
  static Future<void> clearQueue() async {
    final box = await _getSecureChannel();
    await box.clear();
  }
}
