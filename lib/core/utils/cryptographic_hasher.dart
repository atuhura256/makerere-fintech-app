import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Pre-processing SHA-256 utility used to compute frontend verification
/// signatures before payloads are dispatched to the Supabase backend.
///
/// The hash is computed from a pipe-delimited serialisation of transaction
/// fields, matching the format expected by the off-chain Node.js ledger.
///
/// Example:
/// ```dart
/// final sig = runtimeSHA256('userId|productId|500.0|Contribution|prevHash|2026-06-17T...');
/// ```
String runtimeSHA256(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

/// Convenience overload that accepts a Map and serialises via JSON before
/// hashing — useful for block-level integrity checks.
String runtimeSHA256FromMap(Map<String, dynamic> data) {
  final jsonString = jsonEncode(data);
  return runtimeSHA256(jsonString);
}
