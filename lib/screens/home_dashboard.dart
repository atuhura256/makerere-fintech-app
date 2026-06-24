import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/widgets/glass_bottom_nav_bar.dart';
import 'package:makerere_fintech_app/screens/sacco_detail_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  Map<String, dynamic>? _marketOverview;
  List<Map<String, dynamic>> _leaderboard = [];
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
        SupabaseService.getPlatformMarketOverview().catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.getSaccoLeaderboard().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (mounted) {
        setState(() {
          final overviewData = List<Map<String, dynamic>>.from(results[0]);
          _marketOverview = overviewData.isNotEmpty ? overviewData.first : null;
          _leaderboard = List<Map<String, dynamic>>.from(results[1]);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _buildBackground(context),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppConstants.emerald,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildBalanceGlowCard(context),
                  const SizedBox(height: 24),
                  _buildPlatformStats(context),
                  const SizedBox(height: 24),
                  if (_leaderboard.isNotEmpty) ...[
                    _buildLeaderboard(context),
                    const SizedBox(height: 24),
                  ],
                  _buildQuickActions(context),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? AppConstants.darkBg : AppConstants.lightBg,
            isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120, right: -80,
            child: Container(
              width: 280, height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.emerald.withAlpha(6),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.emerald.withAlpha(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final userEmail = SupabaseService.client.auth.currentUser?.email ?? 'Member Node';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back,',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail.split('@').first,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.emerald.withAlpha(15), AppConstants.emerald.withAlpha(5)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.emerald.withAlpha(30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.emerald,
                  boxShadow: [
                    BoxShadow(color: AppConstants.emerald, blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE NODE',
                style: TextStyle(
                  color: AppConstants.emerald,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceGlowCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double totalDynamicAssets = (_marketOverview?['total_assets'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F1A2E), const Color(0xFF0B1222)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1A2332).withAlpha(120)
              : const Color(0xFFD0D5DD).withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.emerald.withAlpha(isDark ? 10 : 6),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Dynamic Savings Pool',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withAlpha(150),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppConstants.emerald.withAlpha(180),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _loading
              ? const SizedBox(
                  width: 30, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald),
                )
              : Text(
                  _formatCurrency(totalDynamicAssets),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.trending_up, color: AppConstants.emerald, size: 12),
              ),
              const SizedBox(width: 6),
              Text(
                '+${_marketOverview?['growth_rate_pct'] ?? 14.5}% this month',
                style: const TextStyle(
                  color: AppConstants.emerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStats(BuildContext context) {
    final totalTransactions = _marketOverview?['total_transactions'] ?? 0;
    final totalMembers = _marketOverview?['active_members_count'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: BlockchainMetricCard(
            label: 'Ledger Txns',
            value: _formatLargeNum(totalTransactions),
            icon: Icons.swap_horiz_rounded,
            color: AppConstants.cyan,
            isLoading: _loading,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: BlockchainMetricCard(
            label: 'Federation Members',
            value: _formatLargeNum(totalMembers),
            icon: Icons.groups_outlined,
            color: AppConstants.violet,
            isLoading: _loading,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockchainSectionHeader(
          title: 'Top Performing Sacco Nodes',
          icon: Icons.emoji_events_outlined,
          accentColor: AppConstants.emerald,
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _leaderboard.take(3).length,
          itemBuilder: (context, index) {
            final sacco = _leaderboard[index];
            return BlockchainCard(
              hasAccentBar: true,
              accentColor: AppConstants.emerald,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SaccoDetailsPage(
                      saccoName: sacco['sacco_name'] ?? 'Federation Node',
                      schemaName: sacco['schema_name'] ?? 'public',
                      pattern: sacco,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppConstants.emerald.withAlpha(20), AppConstants.emerald.withAlpha(5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppConstants.emerald.withAlpha(25), width: 0.5),
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: AppConstants.emerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sacco['sacco_name'] ?? '',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${sacco['member_count'] ?? 0} members · ${sacco['transaction_count'] ?? 0} txns',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(140),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(sacco['total_volume']),
                    style: const TextStyle(
                      color: AppConstants.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlockchainSectionHeader(
          title: 'Quick Actions',
          icon: Icons.flash_on_outlined,
          accentColor: AppConstants.emerald,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BlockchainActionCard(
                label: 'Register SACCO',
                icon: Icons.add_business_outlined,
                color: AppConstants.emerald,
                route: '/tenant-registration',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BlockchainActionCard(
                label: 'View All SACCOs',
                icon: Icons.account_balance_outlined,
                color: AppConstants.cyan,
                route: '/saccos',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCurrency(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000000) return 'UGX ${(v / 1000000000).toStringAsFixed(1)}B';
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  String _formatLargeNum(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toString();
  }
}
