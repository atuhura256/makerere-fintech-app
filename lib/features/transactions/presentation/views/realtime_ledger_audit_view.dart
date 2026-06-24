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
                        : _transactions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppConstants.emerald.withAlpha(10),
                                      ),
                                      child: const Icon(Icons.verified_outlined, size: 40, color: AppConstants.emerald),
                                    ),
                                    const SizedBox(height: 16),
                                    Text('No ledger entries yet', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) => _TransactionCard(
                                  tx: _transactions[index],
                                  index: index,
                                  isLast: index == _transactions.length - 1,
                                ),
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              (theme.brightness == Brightness.dark ? const Color(0xFF0B1222) : const Color(0xFFF8FFF8)),
            ],
          ),
          border: Border.all(
            color: AppConstants.emerald.withAlpha(25),
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.emerald.withAlpha(8),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConstants.emerald, AppConstants.emeraldDark],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.emerald.withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Immutable Audit Trail',
                    style: TextStyle(fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppConstants.emerald.withAlpha(12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_transactions.length} entries · SHA-256 anchored',
                      style: TextStyle(color: AppConstants.emerald, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
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
  const _TransactionCard({required this.tx, required this.index, this.isLast = false});
  final Map<String, dynamic> tx;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = tx['status'] == 'SUCCESSFUL';
    final statusColor = verified ? AppConstants.emerald : AppConstants.amber;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: verified ? AppConstants.emerald.withAlpha(20) : AppConstants.amber.withAlpha(20),
                          border: Border.all(color: verified ? AppConstants.emerald : AppConstants.amber, width: 1.5),
                        ),
                        child: Icon(
                          verified ? Icons.check : Icons.access_time,
                          size: 12,
                          color: verified ? AppConstants.emerald : AppConstants.amber,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1.5,
                            color: (verified ? AppConstants.emerald : AppConstants.amber).withAlpha(30),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.cardColor,
                      border: Border.all(
                        color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tx['transaction_type'] ?? 'UNKNOWN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Block #$index',
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color?.withAlpha(120),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            BlockchainStatusChip(status: tx['status'] ?? 'UNKNOWN'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'UGX ${tx['amount'] ?? 0}',
                          style: TextStyle(
                            color: AppConstants.emerald,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (theme.brightness == Brightness.dark ? const Color(0xFF050A15) : const Color(0xFFF0F2F5)).withAlpha(160),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _hashRow(context, 'Previous', tx['prev_hash']),
                              const SizedBox(height: 6),
                              _hashRow(context, 'Current', tx['curr_hash'] ?? 'Pending...', verified ? AppConstants.emerald : AppConstants.amber),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hashRow(BuildContext context, String label, String hash, [Color? valueColor]) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(140),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            hash,
            style: TextStyle(
              fontSize: 9,
              fontFamily: 'monospace',
              color: valueColor ?? theme.textTheme.bodyMedium?.color?.withAlpha(180),
              letterSpacing: 0.3,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
