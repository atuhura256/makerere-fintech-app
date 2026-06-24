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
        SupabaseService.getPlatformMarketOverview().catchError((e) => <Map<String, dynamic>>[]),
        SupabaseService.getSaccoLeaderboard().catchError((e) => <Map<String, dynamic>>[]),
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
                  _buildBalanceCard(context),
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

    return Container(
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
          color: AppConstants.emerald.withAlpha(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.emerald.withAlpha(6),
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
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail.split('@').first,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.emerald.withAlpha(15), AppConstants.emerald.withAlpha(5)],
              ),
              borderRadius: BorderRadius.circular(20),
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
                    boxShadow: [BoxShadow(color: AppConstants.emerald, blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppConstants.emerald,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double totalDynamicAssets = (_marketOverview?['total_assets'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
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
                'Total Pool Value',
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
                  gradient: LinearGradient(
                    colors: [AppConstants.emerald.withAlpha(12), AppConstants.emerald.withAlpha(5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppConstants.emerald.withAlpha(20)),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppConstants.emerald.withAlpha(180),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _loading
              ? const SizedBox(
                  width: 30, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald),
                )
              : Text(
                  _formatCurrency(totalDynamicAssets),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.1,
                  ),
                ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppConstants.emerald.withAlpha(12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: AppConstants.emerald, size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${_marketOverview?['growth_rate_pct'] ?? 14.5}% this month',
                  style: const TextStyle(
                    color: AppConstants.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformStats(BuildContext context) {
    final totalTransactions = _marketOverview?['total_transactions'] ?? 0;
    final totalMembers = _marketOverview?['active_members_count'] ?? 0;
    final totalSaccos = _marketOverview?['total_saccos'] ?? 0;

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
        const SizedBox(width: 12),
        Expanded(
          child: BlockchainMetricCard(
            label: 'Members',
            value: _formatLargeNum(totalMembers),
            icon: Icons.groups_outlined,
            color: AppConstants.violet,
            isLoading: _loading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BlockchainMetricCard(
            label: 'SACCOs',
            value: _formatLargeNum(totalSaccos),
            icon: Icons.account_balance_rounded,
            color: AppConstants.emerald,
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
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.amber.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events_outlined, size: 16, color: AppConstants.amber),
              ),
              const SizedBox(width: 10),
              Text(
                'Top Performing Nodes',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(_leaderboard.take(3).length, (index) {
          final sacco = _leaderboard[index];
          final isFirst = index == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardColor,
                  (theme.brightness == Brightness.dark ? const Color(0xFF0B1222) : const Color(0xFFFAFCF8)),
                ],
              ),
              border: Border.all(
                color: isFirst
                    ? AppConstants.amber.withAlpha(40)
                    : (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100),
              ),
              boxShadow: isFirst
                  ? [BoxShadow(color: AppConstants.amber.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isFirst
                                ? [AppConstants.amber.withAlpha(25), AppConstants.amber.withAlpha(10)]
                                : [AppConstants.emerald.withAlpha(20), AppConstants.emerald.withAlpha(5)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirst
                                ? AppConstants.amber.withAlpha(30)
                                : AppConstants.emerald.withAlpha(25),
                            width: isFirst ? 1 : 0.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isFirst ? Icons.emoji_events_rounded : Icons.account_balance_rounded,
                            color: isFirst ? AppConstants.amber : AppConstants.emerald,
                            size: 18,
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(sacco['total_volume']),
                            style: TextStyle(
                              color: isFirst ? AppConstants.amber : AppConstants.emerald,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isFirst ? AppConstants.amber : AppConstants.emerald).withAlpha(12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                color: isFirst ? AppConstants.amber : AppConstants.emerald,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on_outlined, size: 16, color: AppConstants.emerald),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
            const SizedBox(width: 8),
            Expanded(
              child: BlockchainActionCard(
                label: 'All SACCOs',
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
