import 'dart:io';
import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/widgets/glass_bottom_nav_bar.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:postgrest/postgrest.dart';
import 'package:share_plus/share_plus.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
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
      final user = SupabaseService.client.auth.currentUser;

      final query = SupabaseService.client
          .from('sacco_transactions')
          .select('*')
          .order('created_at', ascending: false)
          .limit(30) as PostgrestFilterBuilder;

      final response = await query.eq('user_id', user?.id ?? '');

      if (mounted) {
        setState(() {
          _transactions = List<Map<String, dynamic>>.from(response);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Statement Load Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportStatement() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          children: [
            pw.Text('Official Transaction Statement', style: pw.TextStyle(fontSize: 20)),
            pw.Divider(),
            ..._transactions.map((tx) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(tx['transaction_type'] ?? 'N/A'),
                pw.Text('UGX ${tx['amount'] ?? 0}'),
              ]
            )),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/statement.pdf");
    await file.writeAsBytes(await pdf.save());

    if (mounted) {
      await Share.shareXFiles([XFile(file.path)], text: 'Your financial statement');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [theme.scaffoldBackgroundColor, theme.brightness == Brightness.dark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppConstants.emerald,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    sliver: _loading
                        ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald)))
                        : _transactions.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_rounded, size: 48, color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
                                  const SizedBox(height: 12),
                                  Text('No ledger entries found', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((context, index) {
                              final tx = _transactions[index];
                              final bool isIncome = tx['transaction_type'] == 'DEPOSIT';
                              final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
                              return BlockchainCard(
                                hasAccentBar: isIncome,
                                accentColor: isIncome ? AppConstants.emerald : AppConstants.coral,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (isIncome ? AppConstants.emerald : AppConstants.coral).withAlpha(15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: (isIncome ? AppConstants.emerald : AppConstants.coral).withAlpha(25),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Icon(
                                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isIncome ? AppConstants.emerald : AppConstants.coral,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx['transaction_type'] ?? 'TRANSACTION',
                                            style: TextStyle(
                                              color: theme.textTheme.bodyLarge?.color,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ref: ${tx['reference_id'] ?? 'N/A'} · ${_formatDate(tx['created_at'])}',
                                            style: TextStyle(
                                              color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(amount),
                                      style: TextStyle(
                                        color: isIncome ? AppConstants.emerald : AppConstants.coral,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }, childCount: _transactions.length),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.emerald.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.emerald.withAlpha(25), width: 0.5),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: AppConstants.emerald, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Ledger', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${_transactions.length} immutable entries anchored', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            onPressed: _exportStatement,
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppConstants.emerald),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try { final d = DateTime.parse(date); return '${d.day}/${d.month}/${d.year}'; } catch (_) { return ''; }
  }

  String _formatCurrency(dynamic value) {
    final num v = (value is num) ? value : 0;
    return 'UGX ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}
