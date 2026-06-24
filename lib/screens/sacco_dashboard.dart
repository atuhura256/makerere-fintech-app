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
        SupabaseService.getAllSaccos().catchError((e) => <Map<String, dynamic>>[]),
        SupabaseService.getSaccoTradingPatterns().catchError((e) => <Map<String, dynamic>>[]),
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
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F1A2E), const Color(0xFF0B1222)]
              : [Colors.white, const Color(0xFFF0FFF4)],
        ),
        border: Border.all(
          color: (isDark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.emerald.withAlpha(isDark ? 8 : 6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SACCO Networks',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Multi-tenant financial federation nodes',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _headerStat(context, '${_saccos.length}', 'Active Nodes', AppConstants.emerald, Icons.account_balance_rounded),
              const SizedBox(width: 16),
              _headerStat(context, '${_tradingPatterns.length}', 'With Data', AppConstants.cyan, Icons.analytics_outlined),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppConstants.emerald.withAlpha(30)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.emerald,
                        boxShadow: [BoxShadow(color: AppConstants.emerald, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE',
                      style: TextStyle(color: AppConstants.emerald, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(BuildContext context, String value, String label, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.emerald.withAlpha(10),
                ),
                child: const Icon(Icons.account_balance_outlined, size: 40, color: AppConstants.emerald),
              ),
              const SizedBox(height: 16),
              Text('No active financial federations registered.',
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
            ],
          ),
        ),
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
            return _buildSaccoCard(context, index, sacco, pattern);
          },
          childCount: _saccos.length,
        ),
      ),
    );
  }

  Widget _buildSaccoCard(BuildContext context, int index, Map<String, dynamic> sacco, Map<String, dynamic>? pattern) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalVolume = pattern?['total_volume'] ?? 0;
    final txCount = pattern?['transaction_count'] ?? 0;
    final mCount = pattern?['member_count'] ?? 0;
    final trend = pattern?['trend_direction'] ?? 'STABLE';

    final trendColor = trend == 'BULLISH' ? AppConstants.emerald : trend == 'BEARISH' ? AppConstants.coral : AppConstants.amber;
    final trendIcon = trend == 'BULLISH' ? Icons.trending_up : trend == 'BEARISH' ? Icons.trending_down : Icons.trending_flat;

    return GestureDetector(
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F1A2E), const Color(0xFF0B1222)]
                : [Colors.white, const Color(0xFFFAFCF8)],
          ),
          border: Border.all(
            color: (isDark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
          ),
          boxShadow: [
            BoxShadow(
              color: AppConstants.emerald.withAlpha(isDark ? 6 : 4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppConstants.emerald,
                      AppConstants.emerald.withAlpha(60),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppConstants.emerald.withAlpha(25),
                                  AppConstants.emerald.withAlpha(10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppConstants.emerald.withAlpha(25),
                                width: 0.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                sacco['sacco_name']?.toString().substring(0, 2).toUpperCase() ?? 'SC',
                                style: const TextStyle(
                                  color: AppConstants.emerald,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sacco['sacco_name'] ?? '',
                                  style: TextStyle(
                                    color: theme.textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(trendIcon, size: 12, color: trendColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      trend,
                                      style: TextStyle(
                                        color: trendColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '· ${sacco['registration_number'] ?? 'N/A'}',
                                      style: TextStyle(
                                        color: theme.textTheme.bodyMedium?.color?.withAlpha(140),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppConstants.emerald.withAlpha(10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12, color: AppConstants.emerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: (isDark ? const Color(0xFF1A2332) : const Color(0xFFE2E8F0)).withAlpha(160),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _saccoMetric(theme, _formatCurrency(totalVolume), 'Volume', AppConstants.emerald),
                          const Spacer(),
                          _saccoMetric(theme, '$txCount', 'Txns', AppConstants.cyan),
                          const Spacer(),
                          _saccoMetric(theme, '$mCount', 'Members', AppConstants.violet),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saccoMetric(ThemeData theme, String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F1A2E), const Color(0xFF0B1222)]
              : [Colors.white, const Color(0xFFFAFCF8)],
        ),
        border: Border.all(
          color: (isDark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppConstants.emerald.withAlpha(60),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000000) return 'UGX ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }
}
