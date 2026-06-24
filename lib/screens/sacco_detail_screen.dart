import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/screens/payment_web_view_screen.dart';
import 'package:makerere_fintech_app/screens/sacco_join_request_screen.dart';
import 'package:makerere_fintech_app/screens/sacco_admin_portal_screen.dart';
import 'package:makerere_fintech_app/screens/sacco_loan_application_screen.dart';

class SaccoDetailsPage extends StatefulWidget {
  final String saccoName;
  final String schemaName;
  final Map<String, dynamic>? pattern;

  const SaccoDetailsPage({
    super.key,
    required this.saccoName,
    required this.schemaName,
    this.pattern,
  });

  @override
  State<SaccoDetailsPage> createState() => _SaccoDetailsPageState();
}

class _SaccoDetailsPageState extends State<SaccoDetailsPage> {
  List<Map<String, dynamic>> _dailyVolume = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _memberActivity = [];
  bool _loading = true;
  bool _isSaccoMember = false;
  bool _hasAdminAccess = false;
  String _chartPeriod = '30D';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final adminCheck = await SupabaseService.verifyAdminPrivileges(schemaName: widget.schemaName);
      final memberCheck = await SupabaseService.checkMembershipStatus(schemaName: widget.schemaName);

      if (mounted) {
        setState(() {
          _hasAdminAccess = adminCheck;
          _isSaccoMember = memberCheck;
        });
      }
    } catch (e) {
      debugPrint("Security error: $e");
    }

    try {
      final days = _chartPeriod == '7D' ? 7 : _chartPeriod == '90D' ? 90 : 30;

      final results = await Future.wait([
        SupabaseService.getSaccoDailyVolume(schemaName: widget.schemaName, daysBack: days).catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.getProductPerformance(schemaName: widget.schemaName).catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.getMemberActivityPatterns(schemaName: widget.schemaName).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _dailyVolume = List<Map<String, dynamic>>.from(results[0]);
          _products = List<Map<String, dynamic>>.from(results[1]);
          _memberActivity = List<Map<String, dynamic>>.from(results[2]);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDepositSheet(BuildContext context) {
    final theme = Theme.of(context);
    final amountCtrl = TextEditingController();
    Map<String, dynamic>? selectedProduct = _products.isNotEmpty ? _products.first : null;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deposit into ${widget.saccoName}', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Post a real-time savings transaction to the decentralized tenant ledger.', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
              const SizedBox(height: 24),

              if (_products.isNotEmpty) ...[
                Text('Select Savings Account Type', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: selectedProduct,
                      isExpanded: true,
                      dropdownColor: theme.cardColor,
                      items: _products.map((p) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: p,
                          child: Text('${p['product_name']} (${p['interest_rate']}% APR)', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedProduct = val),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text('Transaction Amount (UGX)', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.monetization_on_outlined, color: AppConstants.emerald),
                  hintText: 'e.g., 50000',
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    final double? amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.orangeAccent));
                      return;
                    }

                    setModalState(() => isSubmitting = true);
                    try {
                      final currentUser = SupabaseService.currentUser;
                      if (currentUser == null) throw Exception("User session not found.");

                      const String redirectionTarget = 'https://d23a.github.io/verification-success/';
                      final String paymentUrl = 'https://checkout.flutterwave.com/v3/hosted/pay/test-simulation-token';

                      if (!context.mounted) return;

                      final bool paymentSuccessful = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentWebViewScreen(
                            initialUrl: paymentUrl,
                            redirectUrl: redirectionTarget,
                          ),
                        ),
                      ) ?? false;

                      if (paymentSuccessful) {
                        await SupabaseService.insertTenantTransaction(
                          schemaName: widget.schemaName,
                          payload: {
                            'amount': amount,
                            'transaction_type': 'DEPOSIT',
                            'user_id': currentUser.id,
                            'product_id': selectedProduct?['product_id'] ?? selectedProduct?['id'],
                            'created_at': DateTime.now().toIso8601String(),
                          },
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✔ UGX ${amountCtrl.text} deposited successfully!'), backgroundColor: AppConstants.emerald)
                          );
                          _loadData();
                        }
                      } else {
                        setModalState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction canceled or declined.'), backgroundColor: Colors.orangeAccent));
                        }
                      }
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing deposit: $e'), backgroundColor: Colors.redAccent));
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Deposit Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final p = widget.pattern;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [isDark ? AppConstants.darkBg : AppConstants.lightBg, isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar(context)),
              SliverToBoxAdapter(child: _buildHeroSection(context, p)),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _buildTradingChart(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              SliverToBoxAdapter(child: _buildMetricsGrid(context, p)),
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
              if (_products.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildProductsSection(context)),
                SliverToBoxAdapter(child: const SizedBox(height: 24)),
              ],
              if (_memberActivity.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildMemberActivitySection(context)),
                SliverToBoxAdapter(child: const SizedBox(height: 120)),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(160))),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDepositSheet(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Deposit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.emerald,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SaccoLoanApplicationScreen(
                        saccoId: widget.pattern?['sacco_id'] ?? p?['sacco_id'] ?? '',
                        saccoName: widget.saccoName,
                        schemaName: widget.schemaName,
                      ),
                    ),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.credit_score_outlined, size: 20),
                label: const Text('Request Loan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.emerald,
                  side: const BorderSide(color: AppConstants.emerald, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final activeUserEmail = SupabaseService.client.auth.currentUser?.email ?? '';
    final bool showAdminButton = _hasAdminAccess || (activeUserEmail.toLowerCase().trim() == 'atuhuradavis135@gmail.com');

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),

          if (showAdminButton)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined, color: AppConstants.emerald),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SaccoAdminPortalScreen(
                      saccoName: widget.saccoName,
                      schemaName: widget.schemaName,
                    ),
                  ),
                ).then((_) => _loadData());
              },
            ),
          const SizedBox(width: 8),
          BlockchainBadge(
            label: activeUserEmail.isNotEmpty ? activeUserEmail : 'GUEST_NODE',
            color: AppConstants.emerald,
            icon: Icons.circle,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Map<String, dynamic>? p) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.saccoName, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    BlockchainBadge(label: 'Schema: ${widget.schemaName}', color: AppConstants.emerald),
                    BlockchainBadge(label: '${p?['transaction_count'] ?? 0} transactions', color: AppConstants.cyan),
                  ],
                ),
              ],
            ),
          ),
          if (!_isSaccoMember)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SaccoJoinRequestScreen(
                      saccoId: widget.pattern?['sacco_id'] ?? p?['sacco_id'] ?? '',
                      saccoName: widget.saccoName,
                      schemaName: widget.schemaName,
                    ),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.person_add_alt_1, size: 14),
              label: const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.emerald.withAlpha(25),
                foregroundColor: AppConstants.emerald,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTradingChart(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 240,
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withAlpha(120))),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald)),
      );
    }
    if (_dailyVolume.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 100,
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withAlpha(120))),
        child: Center(child: Text('No trading data yet', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < _dailyVolume.length; i++) {
      final amt = (_dailyVolume[i]['total_amount'] as num?)?.toDouble() ?? 0;
      spots.add(FlSpot(i.toDouble(), amt));
    }
    final maxY = spots.fold<double>(0, (p, s) => s.y > p ? s.y : p);
    final minY = spots.fold<double>(spots.first.y, (p, s) => s.y < p ? s.y : p);
    final pad = (maxY - minY) * 0.15;

    return BlockchainCard(
      hasGlow: true,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Trading Volume', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              _buildPeriodChip('7D'),
              const SizedBox(width: 6),
              _buildPeriodChip('30D'),
              const SizedBox(width: 6),
              _buildPeriodChip('90D'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: (minY - pad).clamp(0, double.infinity),
                maxY: maxY + pad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: ((maxY - minY) / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor.withAlpha(80), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppConstants.emerald,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppConstants.emerald.withAlpha(30),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppConstants.emerald.withAlpha(50), AppConstants.emerald.withAlpha(5)],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => theme.cardColor,
                    tooltipPadding: const EdgeInsets.all(12),
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (spots) => spots.map((s) {
                      return LineTooltipItem(
                        _formatCompact(s.y),
                        TextStyle(color: AppConstants.emerald, fontWeight: FontWeight.w700, fontSize: 12),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final active = _chartPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() => _chartPeriod = period);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppConstants.emerald : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? null : Border.all(color: Theme.of(context).dividerColor.withAlpha(120)),
        ),
        child: Text(
          period,
          style: TextStyle(
            color: active ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 11, fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic>? p) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlockchainSectionHeader(title: 'Key Metrics', icon: Icons.analytics_outlined),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              BlockchainMetricCard(label: 'Total Volume', value: _formatCurrency(p?['total_volume']), icon: Icons.monetization_on, color: AppConstants.emerald),
              BlockchainMetricCard(label: 'Transactions', value: '${p?['transaction_count'] ?? 0}', icon: Icons.swap_horiz, color: AppConstants.cyan),
              BlockchainMetricCard(label: 'Members', value: '${p?['member_count'] ?? 0}', icon: Icons.groups, color: AppConstants.violet),
              BlockchainMetricCard(label: 'Avg Transaction', value: _formatCurrency(p?['avg_transaction_amount']), icon: Icons.bar_chart, color: AppConstants.amber),
              BlockchainMetricCard(label: '30d Volume', value: _formatCurrency(p?['last_30d_volume']), icon: Icons.trending_up, color: AppConstants.emerald),
              BlockchainMetricCard(label: 'Change', value: '${p?['volume_change_pct'] != null ? (p!['volume_change_pct'] >= 0 ? '+' : '') : ''}${(p?['volume_change_pct'] as num? ?? 0).toStringAsFixed(1)}%', icon: Icons.change_circle, color: (p?['volume_change_pct'] as num? ?? 0) >= 0 ? AppConstants.emerald : AppConstants.coral),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlockchainSectionHeader(title: 'Product Performance', icon: Icons.inventory_2_outlined),
          const SizedBox(height: 16),
          ..._products.map((p) => BlockchainCard(
            hasAccentBar: true,
            accentColor: AppConstants.emerald,
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppConstants.emerald.withAlpha(20), AppConstants.emerald.withAlpha(5)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppConstants.emerald.withAlpha(20), width: 0.5),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: AppConstants.emerald, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['product_name'] ?? '', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('${p['member_count']} members · ${p['transaction_count']} txns', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatCurrency(p['total_invested']), style: TextStyle(color: AppConstants.emerald, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${p['interest_rate']}% APR', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 10)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMemberActivitySection(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlockchainSectionHeader(title: 'Member Activity', icon: Icons.people_outline),
          const SizedBox(height: 16),
          BlockchainCard(
            child: Column(
              children: _memberActivity.take(3).map((m) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.violet.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppConstants.violet.withAlpha(20), width: 0.5),
                      ),
                      child: const Icon(Icons.people_outline, color: AppConstants.violet, size: 16),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(m['period_label'] ?? '', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500, fontSize: 13)),
                    ),
                    Text('${m['active_members']} active', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000000) return 'UGX ${(v / 1000000000).toStringAsFixed(2)}B';
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  String _formatCompact(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }
}
