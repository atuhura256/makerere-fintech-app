import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/screens/sacco_detail_screen.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/widgets/glass_bottom_nav_bar.dart';

class SaccoDashboard extends StatefulWidget {
  const SaccoDashboard({super.key});

  @override
  State<SaccoDashboard> createState() => _SaccoDashboardState();
}

class _SaccoDashboardState extends State<SaccoDashboard> {
  List<Map<String, dynamic>> _saccos = [];
  List<Map<String, dynamic>> _tradingPatterns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        SupabaseService.getAllSaccos().catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.getSaccoTradingPatterns().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          _saccos = List<Map<String, dynamic>>.from(results[0]);
          _tradingPatterns = List<Map<String, dynamic>>.from(results[1]);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _findPattern(String schemaName) {
    try {
      return _tradingPatterns.firstWhere(
        (element) => element['schema_name'].toString().toLowerCase().trim() == schemaName.toLowerCase().trim()
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? AppConstants.darkBg : AppConstants.lightBg,
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppConstants.emerald,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  _buildSaccoGridList(context),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 20, left: 20, right: 20,
            child: GlassBottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [
              isDark ? AppConstants.darkBg : AppConstants.lightBg,
              isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SACCO Networks', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.emerald.withAlpha(25)),
                ),
                child: Text('${_saccos.length} ACTIVE NODES', style: const TextStyle(color: AppConstants.emerald, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Select a multi-tenant financial federation node to enter decentralized ledgers.', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSaccoGridList(BuildContext context) {
    if (_loading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((_, __) => _buildSkeletonCard(context), childCount: 3),
        ),
      );
    }
    if (_saccos.isEmpty) {
      return SliverFillRemaining(
        child: Center(child: Text('No active financial federations registered.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final sacco = _saccos[index];
            final schema = sacco['schema_name'] ?? '';
            final pattern = _findPattern(schema);
            return _buildSaccoRowCard(context, sacco, pattern);
          },
          childCount: _saccos.length,
        ),
      ),
    );
  }

  Widget _buildSaccoRowCard(BuildContext context, Map<String, dynamic> sacco, Map<String, dynamic>? pattern) {
    final theme = Theme.of(context);

    final totalVolume = pattern?['total_volume'] ?? 0;
    final txCount = pattern?['transaction_count'] ?? 0;
    final mCount = pattern?['member_count'] ?? 0;

    return BlockchainCard(
      hasAccentBar: true,
      accentColor: AppConstants.emerald,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SaccoDetailsPage(
              saccoName: sacco['sacco_name'] ?? 'SACCO Ledger',
              schemaName: sacco['schema_name'] ?? 'public',
              pattern: pattern ?? {'sacco_id': sacco['sacco_id']},
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(sacco['sacco_name'] ?? '', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.emerald.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppConstants.emerald),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Reg No: ${sacco['registration_number'] ?? 'N/A'} · Tenant: ${sacco['schema_name']}', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetric(theme, 'Liquidity Pool', _formatCurrency(totalVolume), AppConstants.emerald),
                _buildMetric(theme, 'Ledger Transactions', '$txCount Txns', AppConstants.cyan),
                _buildMetric(theme, 'Active Members', '$mCount Profiles', AppConstants.violet),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(ThemeData theme, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(140), fontSize: 10)),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 170,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(120)),
      ),
      child: Center(
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald.withAlpha(60)),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}
