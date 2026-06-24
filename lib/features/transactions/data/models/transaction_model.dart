import 'package:makerere_fintech_app/core/utils/cryptographic_hasher.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';

/// Cryptographic transaction model for the Secure Multi-SACCO Platform.
///
/// Each transaction carries:
/// - A [previousBlockHash] linking it to the preceding block (chain continuity).
/// - A [currentBlockHash] populated **exclusively** by the off-chain Node.js
///   ledger engine — never written from the Flutter client.
/// - [isVerified] flipped to `true` by the Node.js verification process.
///
/// The client computes [computeFrontendVerificationSignature] as a local
/// integrity pre-check before dispatching the payload upstream.
class TransactionModel {
  final String? id;
  final String userId;
  final String productId;
  final double amount;

  /// Must be one of [AppConstants.transactionTypes].
  final String type;

  /// SHA-256 hash of the previous block — required for chain continuity.
  final String previousBlockHash;

  /// Populated by the Node.js off-chain engine; `null` while pending.
  final String? currentBlockHash;

  /// Set to `true` by the Node.js verification process once anchored.
  final bool isVerified;

  final DateTime timestamp;

  const TransactionModel({
    this.id,
    required this.userId,
    required this.productId,
    required this.amount,
    required this.type,
    required this.previousBlockHash,
    this.currentBlockHash,
    required this.isVerified,
    required this.timestamp,
  });

  // ── Serialisation ──────────────────────────────────────────────────────────

  /// Builds the payload sent to Supabase.
  ///
  /// [currentBlockHash] and [isVerified] are intentionally omitted — they are
  /// managed exclusively by the off-chain Node.js ledger.
  Map<String, dynamic> toSupabasePayload() => {
        'user_id': userId,
        'product_id': productId,
        'amount': amount,
        'transaction_type': type,
        'previous_block_hash': previousBlockHash,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Builds the full local representation including off-chain fields.
  Map<String, dynamic> toJson() => {
        if (id != null) 'transaction_id': id,
        'user_id': userId,
        'product_id': productId,
        'amount': amount,
        'transaction_type': type,
        'previous_block_hash': previousBlockHash,
        if (currentBlockHash != null) 'current_block_hash': currentBlockHash,
        'is_verified': isVerified,
        'created_at': timestamp.toIso8601String(),
      };

  /// Reconstructs a [TransactionModel] from a Supabase row or local JSON map.
  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['transaction_id'] as String?,
        userId: json['user_id'] as String? ?? '',
        productId: json['product_id'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        type: json['transaction_type'] as String? ?? AppConstants.txContribution,
        previousBlockHash: json['previous_block_hash'] as String? ?? '0',
        currentBlockHash: json['current_block_hash'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        timestamp: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  // ── Integrity ──────────────────────────────────────────────────────────────

  /// Computes a frontend SHA-256 verification signature from the canonical
  /// pipe-delimited string. This is a **pre-flight check** — the authoritative
  /// hash is computed and stored by the Node.js off-chain engine.
  ///
  /// Format: `userId|productId|amount|type|previousBlockHash|isoTimestamp`
  String computeFrontendVerificationSignature() {
    final serialString =
        '$userId|$productId|$amount|$type|$previousBlockHash|${timestamp.toIso8601String()}';
    return runtimeSHA256(serialString);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Formats [amount] as a human-readable UGX string.
  String get formattedAmount {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${AppConstants.currencySymbol} $formatted';
  }

  /// Returns `true` when this transaction is pending off-chain anchoring.
  bool get isPendingVerification =>
      currentBlockHash == null || !isVerified;

  @override
  String toString() =>
      'TransactionModel(id: $id, type: $type, amount: $amount, verified: $isVerified)';
}
