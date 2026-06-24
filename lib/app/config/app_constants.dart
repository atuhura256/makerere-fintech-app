import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Makerere Fintech';
  static const String platformLabel = 'Secure Multi-SACCO Platform';
  static const String platformSubtitle = 'Powered by SHA-256 chain integrity';

  // ── Blockchain Premium Color Palette (Darker Modern) ──────────────────────
  static const Color emerald = Color(0xFF00D68F);
  static const Color emeraldDark = Color(0xFF00A876);
  static const Color emeraldLight = Color(0xFF50F5B0);
  static const Color navy = Color(0xFF050A15);
  static const Color slate = Color(0xFF475569);
  static const Color coral = Color(0xFFFF4757);
  static const Color amber = Color(0xFFFFB84D);
  static const Color violet = Color(0xFF7C4DFF);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color pink = Color(0xFFFF4081);
  static const Color chainBlue = Color(0xFF2979FF);

  // Dark mode surfaces (deeper, more premium)
  static const Color darkBg = Color(0xFF050A15);
  static const Color darkCard = Color(0xFF0B1222);
  static const Color darkCardElevated = Color(0xFF0F1A2E);
  static const Color darkBorder = Color(0xFF162033);

  // Light mode surfaces (refined)
  static const Color lightBg = Color(0xFFF0F2F5);
  static const Color lightCard = Colors.white;
  static const Color lightBorder = Color(0xFFD0D5DD);

  // ── Transaction types ─────────────────────────────────────────────────────
  static const String txContribution = 'Contribution';
  static const String txWithdrawal = 'Withdrawal';
  static const String txLoanRepayment = 'Loan_Repayment';
  static const List<String> transactionTypes = [
    txContribution,
    txWithdrawal,
    txLoanRepayment,
  ];

  // ── Role labels ────────────────────────────────────────────────────────────
  static const String roleSuperAdmin = 'Super_Admin';
  static const String roleSaccoAdmin = 'SACCO_Admin';
  static const String roleAccountant = 'Accountant';
  static const String roleMember = 'Member';

  // ── Hive ───────────────────────────────────────────────────────────────────
  static const String offlineQueueBox = 'encrypted_tx_queue_payloads';

  // ── Currency ───────────────────────────────────────────────────────────────
  static const String currencySymbol = 'UGX';
}
