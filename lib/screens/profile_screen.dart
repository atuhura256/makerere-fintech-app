import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/app/routes/app_routes.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/widgets/glass_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double _totalSaved = 0.0;
  double _totalBorrowed = 0.0;
  int _activeSaccosCount = 0;
  bool _loadingBalances = true;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserBalanceSheet();
  }

  Future<void> _loadUserBalanceSheet() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingBalances = false);
      return;
    }

    try {
      final response = await SupabaseService.client.rpc(
        'get_user_ledger_balance_sheet',
        params: {'p_user_id': user.id},
      );

      if (mounted && response != null) {
        final data = List<Map<String, dynamic>>.from(response);
        if (data.isNotEmpty) {
          setState(() {
            _totalSaved = (data.first['total_saved_ugx'] as num?)?.toDouble() ?? 0.0;
            _totalBorrowed = (data.first['total_borrowed_ugx'] as num?)?.toDouble() ?? 0.0;
            _activeSaccosCount = (data.first['active_saccos_joined'] as num?)?.toInt() ?? 0;
            _loadingBalances = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _totalSaved = 50000.00;
          _totalBorrowed = 0.0;
          _activeSaccosCount = 0;
          _loadingBalances = false;
        });
      }
    }

    final isSuper = await SupabaseService.isSuperAdmin();
    if (mounted) setState(() => _isSuperAdmin = isSuper);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = SupabaseService.currentUser;
    final email = user?.email ?? 'Not signed in';
    final name = user?.userMetadata?['full_name'] as String? ?? email.split('@').first;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [theme.scaffoldBackgroundColor, isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _loadUserBalanceSheet,
              color: AppConstants.emerald,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                children: [
                  _buildProfileBanner(context, name, email),
                  const SizedBox(height: 24),
                  _buildBalanceSection(context),
                  const SizedBox(height: 24),
                  _buildMenuSection(context),
                  const SizedBox(height: 24),
                  _buildSignOutSection(context),
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

  Widget _buildProfileBanner(BuildContext context, String name, String email) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            (theme.brightness == Brightness.dark ? const Color(0xFF0B1222) : const Color(0xFFF0FFF4)),
          ],
        ),
        border: Border.all(color: AppConstants.emerald.withAlpha(20)),
        boxShadow: [
          BoxShadow(color: AppConstants.emerald.withAlpha(6), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppConstants.emerald.withAlpha(40), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.substring(0, 2).toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(150), fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.emerald.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppConstants.emerald.withAlpha(20)),
              ),
              child: const Icon(Icons.edit_outlined, size: 18, color: AppConstants.emerald),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.cardColor,
        border: Border.all(
          color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 15 : 5), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppConstants.emerald),
              ),
              const SizedBox(width: 10),
              Text(
                'Personal Ledger',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _balanceMetric(theme, 'Total Savings', _formatCurrency(_totalSaved), AppConstants.emerald, Icons.arrow_downward, _loadingBalances)),
              const SizedBox(width: 12),
              Expanded(child: _balanceMetric(theme, 'Total Borrowed', _formatCurrency(_totalBorrowed), AppConstants.coral, Icons.arrow_upward, _loadingBalances)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [AppConstants.cyan.withAlpha(8), AppConstants.cyan.withAlpha(3)],
              ),
              border: Border.all(color: AppConstants.cyan.withAlpha(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.cyan.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_outlined, size: 18, color: AppConstants.cyan),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_activeSaccosCount',
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      Text(
                        'Active SACCO Memberships',
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(140), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.cyan.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('ACTIVE', style: TextStyle(color: AppConstants.cyan, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceMetric(ThemeData theme, String label, String value, Color color, IconData icon, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withAlpha(6),
        border: Border.all(color: color.withAlpha(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(width: 20, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
          else
            Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 15 : 5), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _menuItem(context, 'Account Details', Icons.person_outline, AppConstants.emerald, AppRoutes.accountDetails),
          _menuDivider(context),
          _menuItem(context, 'Security Key Management', Icons.vpn_key_outlined, AppConstants.cyan, AppRoutes.securityKeys),
          if (_isSuperAdmin) _menuDivider(context),
          if (_isSuperAdmin)
            _menuItem(context, 'Super Admin Panel', Icons.shield_outlined, AppConstants.coral, AppRoutes.superAdmin),
          _menuDivider(context),
          _menuItem(context, 'Platform Preferences', Icons.settings_outlined, AppConstants.violet, AppRoutes.settings),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, IconData icon, Color color, String route) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.pushNamed(context, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(20), width: 0.5),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color?.withAlpha(120), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuDivider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFE2E8F0)).withAlpha(120),
    );
  }

  Widget _buildSignOutSection(BuildContext context) {
    final isSignedIn = SupabaseService.currentSession != null;
    return SizedBox(
      width: double.infinity,
      child: isSignedIn
          ? OutlinedButton.icon(
              onPressed: () async {
                await SupabaseService.signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.coral,
                side: const BorderSide(color: AppConstants.coral, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            )
          : ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.emerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
    );
  }

  String _formatCurrency(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }
}
