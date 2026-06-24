import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/widgets/glass_bottom_nav_bar.dart';

class DashboardReportsScreen extends StatefulWidget {
  const DashboardReportsScreen({super.key});

  @override
  State<DashboardReportsScreen> createState() => _DashboardReportsScreenState();
}

class _DashboardReportsScreenState extends State<DashboardReportsScreen> {
  Map<String, dynamic>? _overview;
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getPlatformMarketOverview(),
        SupabaseService.getSaccoLeaderboard(),
      ]);
      if (mounted) {
        setState(() {
          _overview = results[0].isNotEmpty ? results[0].first : null;
          _leaderboard = results[1];
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
            child: Stack(
              children: [
                Positioned(top: -100, right: -80, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: AppConstants.emerald.withAlpha(6)))),
              ],
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppConstants.emerald,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildMetricsGrid(context),
                  const SizedBox(height: 24),
                  _buildRevenueChart(context),
                  const SizedBox(height: 24),
                  _buildLeaderboardSection(context),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.emerald.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.emerald.withAlpha(25), width: 0.5),
          ),
          child: const Icon(Icons.dashboard_rounded, color: AppConstants.emerald, size: 24),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard & Reports', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('Real-time financial overview', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    final theme = Theme.of(context);
    final o = _overview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockchainSectionHeader(title: 'Financial Overview', icon: Icons.analytics_outlined),
        const SizedBox(height: 16),
        if (_loading)
          ...List.generate(4, (_) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.dividerColor.withAlpha(120))),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald.withAlpha(80)))),
          ))
        else
          ...[
            _buildMetricRow(theme, 'Total Volume', _formatCurrency(o?['total_volume']), Icons.account_balance, AppConstants.emerald),
            _buildMetricRow(theme, 'Total Members', '${o?['total_members'] ?? 0}', Icons.groups, AppConstants.cyan),
            _buildMetricRow(theme, 'Total Transactions', '${o?['total_transactions'] ?? 0}', Icons.swap_horiz, AppConstants.violet),
            _buildMetricRow(theme, 'Active SACCOs', '${o?['active_saccos'] ?? 0} / ${o?['total_saccos'] ?? 0}', Icons.business, AppConstants.amber),
            _buildMetricRow(theme, 'Avg SACCO Volume', _formatCurrency(o?['avg_sacco_volume']), Icons.bar_chart, AppConstants.pink),
            _buildMetricRow(theme, 'Top Performer', o?['top_performing_sacco'] ?? 'N/A', Icons.emoji_events, AppConstants.emerald),
          ],
      ],
    );
  }

  Widget _buildMetricRow(ThemeData theme, String label, String value, IconData icon, Color color) {
    return BlockchainCard(
      hasAccentBar: true,
      accentColor: color,
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(25), width: 0.5),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13))),
          Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockchainSectionHeader(title: 'Revenue Distribution', icon: Icons.bar_chart_outlined),
        const SizedBox(height: 16),
        BlockchainCard(
          hasGlow: true,
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) {
                    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                    final i = value.toInt();
                    return i >= 0 && i < months.length
                        ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(months[i], style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 9)))
                        : const Text('');
                  }, reservedSize: 20)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, _) => Text('${value.toInt()}B', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 9)), reservedSize: 28)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 2, getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor.withAlpha(80), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: [3.2,4.8,3.9,5.1,6.3,5.7,7.2,8.1,7.8,9.2,8.5,9.8][i], color: i < 6 ? AppConstants.emerald : AppConstants.cyan, width: 12, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)))])),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockchainSectionHeader(title: 'SACCO Leaderboard', icon: Icons.emoji_events_outlined),
        const SizedBox(height: 16),
        if (_leaderboard.isEmpty)
          BlockchainCard(
            child: Center(child: Text('No SACCO data yet', style: TextStyle(color: theme.textTheme.bodyMedium?.color))),
          )
        else
          ..._leaderboard.map((item) => BlockchainCard(
            hasAccentBar: true,
            accentColor: AppConstants.emerald,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppConstants.emerald.withAlpha(20), AppConstants.emerald.withAlpha(5)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.emerald.withAlpha(25), width: 0.5),
                  ),
                  child: Center(child: Text('#${item['rank']}', style: TextStyle(color: AppConstants.emerald, fontWeight: FontWeight.w700, fontSize: 12))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item['sacco_name'] ?? '', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 13))),
                Text(_formatCurrency(item['total_volume']), style: TextStyle(color: AppConstants.emerald, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          )),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000000) return 'UGX ${(v / 1000000000).toStringAsFixed(2)}B';
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }
}
