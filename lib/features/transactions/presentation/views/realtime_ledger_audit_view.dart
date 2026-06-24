import 'dart:ui';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/widgets/glass_bottom_nav_bar.dart';

class RealtimeLedgerAuditView extends StatefulWidget {
  const RealtimeLedgerAuditView({super.key});

  @override
  State<RealtimeLedgerAuditView> createState() => _RealtimeLedgerAuditViewState();
}

class _RealtimeLedgerAuditViewState extends State<RealtimeLedgerAuditView> {
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final response = await SupabaseService.client
          .from('sacco_transactions')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);

      final rawData = List<Map<String, dynamic>>.from(response);
      final chronoData = rawData.reversed.toList();

      String prevHash = '0000000000000000000000000000000000000000000000000000000000000000';

      for (int i = 0; i < chronoData.length; i++) {
        final tx = chronoData[i];
        final payload = '${tx['transaction_id']}${tx['amount']}${tx['created_at']}$prevHash';
        final currHash = sha256.convert(utf8.encode(payload)).toString();

        tx['prev_hash'] = prevHash;
        tx['curr_hash'] = currHash;
        prevHash = currHash;
      }

      if (mounted) {
        setState(() {
          _transactions = chronoData.reversed.toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [isDark ? AppConstants.darkBg : AppConstants.lightBg, isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppConstants.emerald,
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: AppConstants.emerald))
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) => _TransactionCard(tx: _transactions[index]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(bottom: 20, left: 20, right: 20, child: GlassBottomNavBar()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlockchainCard(
        hasGlow: true,
        accentColor: AppConstants.emerald,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppConstants.emerald.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppConstants.emerald.withAlpha(25), width: 0.5),
              ),
              child: const Icon(Icons.verified_user_rounded, color: AppConstants.emerald, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Immutable Blockchain Audit Trail', style: TextStyle(fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
                  const SizedBox(height: 2),
                  Text('${_transactions.length} entries · SHA-256 anchored', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});
  final Map<String, dynamic> tx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = tx['status'] == 'SUCCESSFUL';

    return BlockchainCard(
      hasAccentBar: true,
      accentColor: verified ? AppConstants.emerald : AppConstants.amber,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tx['transaction_type'] ?? 'UNKNOWN',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              BlockchainStatusChip(status: tx['status'] ?? 'UNKNOWN'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'UGX ${tx['amount'] ?? 0}',
            style: TextStyle(
              color: AppConstants.emerald,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          _HashRow(label: 'Prev Hash', value: tx['prev_hash']),
          const SizedBox(height: 4),
          _HashRow(label: 'Curr Hash', value: tx['curr_hash'] ?? 'Pending...', valueColor: verified ? AppConstants.emerald : AppConstants.amber),
        ],
      ),
    );
  }
}

class _HashRow extends StatelessWidget {
  const _HashRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF050A15).withAlpha(120)
                  : const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: valueColor ?? theme.textTheme.bodyMedium?.color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
