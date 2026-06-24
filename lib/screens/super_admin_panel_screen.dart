import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

class SuperAdminPanelScreen extends StatefulWidget {
  const SuperAdminPanelScreen({super.key});

  @override
  State<SuperAdminPanelScreen> createState() => _SuperAdminPanelScreenState();
}

class _SuperAdminPanelScreenState extends State<SuperAdminPanelScreen> {
  bool _authorized = false;
  bool _checking = true;
  int _usersCount = 0;
  int _saccosCount = 0;
  int _pendingLoans = 0;
  int _pendingMemberships = 0;
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _allSaccos = [];
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _verifyAndLoad();
  }

  Future<void> _verifyAndLoad() async {
    final isAdmin = await SupabaseService.isSuperAdmin();
    if (!mounted) return;
    if (!isAdmin) {
      setState(() => _checking = false);
      return;
    }
    setState(() => _authorized = true);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getAllSaccos().catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.client.from('profiles').select('id, email, full_name, phone_number, created_at, status').catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.client.from('sacco_loan_requests').select('*').eq('status', 'PENDING').catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.client.from('sacco_membership_requests').select('*').eq('status', 'PENDING').catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.client.from('super_admins').select('*').catchError((_) => <Map<String, dynamic>>[]),
      ]);

      if (!mounted) return;

      setState(() {
        _allSaccos = List<Map<String, dynamic>>.from(results[0]);
        _allUsers = List<Map<String, dynamic>>.from(results[1]);
        _pendingLoans = (results[2] as List).length;
        _pendingMemberships = (results[3] as List).length;
        _admins = List<Map<String, dynamic>>.from(results[4]);
        _saccosCount = _allSaccos.length;
        _usersCount = _allUsers.length;
        _checking = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_checking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald),
              const SizedBox(height: 16),
              Text('Verifying credentials...', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ],
          ),
        ),
      );
    }

    if (!_authorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restricted Access')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 64, color: AppConstants.coral.withAlpha(120)),
              const SizedBox(height: 16),
              Text('Access Denied', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Super admin privileges required.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [theme.scaffoldBackgroundColor, isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppConstants.emerald,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(theme),
                const SizedBox(height: 24),
                _buildStatsRow(theme),
                const SizedBox(height: 24),
                _buildSection(theme, Icons.people_outline, 'User Management', 'View and manage all platform users', _usersCount, 'users', AppConstants.cyan),
                const SizedBox(height: 14),
                _buildSection(theme, Icons.account_balance_outlined, 'SACCO Management', 'Approve registrations, view all SACCOS', _saccosCount, 'saccos', AppConstants.emerald),
                const SizedBox(height: 14),
                _buildSection(theme, Icons.request_quote_outlined, 'Loan Requests', 'Review and process loan applications', _pendingLoans, 'loans', AppConstants.amber),
                const SizedBox(height: 14),
                _buildSection(theme, Icons.person_add_alt_1_outlined, 'Membership Requests', 'Approve or reject membership requests', _pendingMemberships, 'memberships', AppConstants.violet),
                const SizedBox(height: 14),
                _buildSection(theme, Icons.admin_panel_settings_outlined, 'Admin Management', 'Add or remove super administrators', _admins.length, 'admins', AppConstants.coral),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [theme.cardColor, (theme.brightness == Brightness.dark ? const Color(0xFF0B1222) : const Color(0xFFF0FFF4))],
        ),
        border: Border.all(color: AppConstants.emerald.withAlpha(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppConstants.emerald.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform Control Panel', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Full system access · ${_admins.length} admin${_admins.length == 1 ? '' : 's'} active', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(theme, 'Users', _usersCount.toString(), Icons.people, AppConstants.cyan)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(theme, 'SACCOs', _saccosCount.toString(), Icons.account_balance, AppConstants.emerald)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard(theme, 'Pending', (_pendingLoans + _pendingMemberships).toString(), Icons.pending_actions, AppConstants.amber)),
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: color.withAlpha(20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, IconData icon, String title, String subtitle, int count, String sectionId, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.cardColor,
        border: Border.all(color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _navigateToSection(sectionId),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withAlpha(25), width: 0.5),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withAlpha(30)),
                  ),
                  child: Text(count.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color?.withAlpha(100), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSection(String sectionId) {
    switch (sectionId) {
      case 'users':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const _UserManagementScreen()));
        break;
      case 'saccos':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const _SaccoManagementScreen()));
        break;
      case 'loans':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const _LoanManagementScreen()));
        break;
      case 'memberships':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const _MembershipManagementScreen()));
        break;
      case 'admins':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const _AdminManagementScreen()));
        break;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

class _UserManagementScreen extends StatefulWidget {
  const _UserManagementScreen();

  @override
  State<_UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<_UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select('id, email, full_name, phone_number, created_at, status')
          .order('created_at', ascending: false);
      if (mounted) setState(() { _users = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeUser(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove User'),
        content: Text('Delete $userName permanently? This removes all their data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deleting = true);
    try {
      await SupabaseService.client.rpc('admin_delete_user', params: {'p_user_id': userId});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User removed permanently'), backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.w700)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
          : _users.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline, size: 48, color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
              const SizedBox(height: 12),
              Text('No users found', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final u = _users[index];
                final name = u['full_name'] as String? ?? 'Unknown';
                final email = u['email'] as String? ?? '';
                final phone = u['phone_number'] as String? ?? '';
                final status = u['status'] as String? ?? 'ACTIVE';
                final isActive = status == 'ACTIVE';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.cardColor,
                    border: Border.all(color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(80)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: isActive ? [AppConstants.emerald, AppConstants.emeraldDark] : [Colors.grey, Colors.grey]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                              if (phone.isNotEmpty)
                                Text(phone, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(120), fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isActive ? AppConstants.emerald : AppConstants.coral).withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status, style: TextStyle(color: isActive ? AppConstants.emerald : AppConstants.coral, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _deleting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: _deleting ? null : () => _removeUser(u['id'], name),
                          tooltip: 'Remove user',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SACCO MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

class _SaccoManagementScreen extends StatefulWidget {
  const _SaccoManagementScreen();

  @override
  State<_SaccoManagementScreen> createState() => _SaccoManagementScreenState();
}

class _SaccoManagementScreenState extends State<_SaccoManagementScreen> {
  List<Map<String, dynamic>> _saccos = [];
  bool _loading = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.client
          .from('saccos')
          .select('*')
          .order('created_at', ascending: false);
      if (mounted) setState(() { _saccos = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSaccoStatus(Map<String, dynamic> sacco) async {
    final currentStatus = sacco['status'] as String? ?? 'ACTIVE';
    final newStatus = currentStatus == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    try {
      await SupabaseService.client
          .from('saccos')
          .update({'status': newStatus})
          .eq('sacco_id', sacco['sacco_id']);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('SACCO ${newStatus == 'ACTIVE' ? 'activated' : 'suspended'}'),
          backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {}
  }

  Future<void> _deleteSacco(String saccoId, String saccoName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete SACCO'),
        content: Text('Delete $saccoName permanently? All members, loans, and transactions will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deleting = true);
    try {
      await SupabaseService.client.rpc('admin_delete_sacco', params: {'p_sacco_id': saccoId});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('SACCO deleted permanently'), backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _deleting = false);
  }

  void _viewMembers(Map<String, dynamic> sacco) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _SaccoMembersScreen(sacco: sacco),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('SACCO Management', style: TextStyle(fontWeight: FontWeight.w700)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
          : _saccos.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.account_balance_outlined, size: 48, color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
              const SizedBox(height: 12), Text('No SACCOs found', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _saccos.length,
              itemBuilder: (context, index) {
                final s = _saccos[index];
                final name = s['sacco_name'] as String? ?? '';
                final reg = s['registration_number'] as String? ?? '';
                final status = s['status'] as String? ?? 'ACTIVE';
                final isActive = status == 'ACTIVE';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.cardColor,
                    border: Border.all(color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(80)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: isActive ? [AppConstants.emerald, AppConstants.emeraldDark] : [Colors.grey, Colors.grey]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(reg, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.group_outlined, color: AppConstants.cyan, size: 20),
                          onPressed: () => _viewMembers(s),
                          tooltip: 'View members',
                        ),
                        IconButton(
                          icon: Icon(isActive ? Icons.check_circle : Icons.pause_circle, color: isActive ? AppConstants.emerald : AppConstants.coral, size: 20),
                          onPressed: () => _toggleSaccoStatus(s),
                          tooltip: isActive ? 'Suspend' : 'Activate',
                        ),
                        IconButton(
                          icon: _deleting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: _deleting ? null : () => _deleteSacco(s['sacco_id'], name),
                          tooltip: 'Delete SACCO',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOAN MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

class _LoanManagementScreen extends StatefulWidget {
  const _LoanManagementScreen();

  @override
  State<_LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<_LoanManagementScreen> {
  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.client
          .from('sacco_loan_requests')
          .select('*')
          .order('created_at', ascending: false);
      if (mounted) setState(() { _loans = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolveLoan(String loanId, String action) async {
    try {
      await SupabaseService.client.rpc('resolve_sacco_loan_request', params: {
        'p_loan_id': loanId,
        'p_action': action,
        'p_blockchain_hash': action == 'APPROVE' || action == 'DISBURSE'
            ? '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}${loanId.substring(0, 8)}'
            : null,
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Loan ${action}d successfully'),
          backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return AppConstants.amber;
      case 'APPROVED': return AppConstants.emerald;
      case 'DISBURSED': return AppConstants.cyan;
      case 'REJECTED': return AppConstants.coral;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Management', style: TextStyle(fontWeight: FontWeight.w700)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
          : _loans.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.request_quote_outlined, size: 48, color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
              const SizedBox(height: 12), Text('No loan requests', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _loans.length,
              itemBuilder: (context, index) {
                final l = _loans[index];
                final status = l['status'] as String? ?? 'PENDING';
                final color = _statusColor(status);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.cardColor,
                    border: Border.all(color: color.withAlpha(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                              child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                            const Spacer(),
                            Text('UGX ${(l['principal_amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Applicant: ${l['applicant_name'] ?? 'Unknown'}', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                        Text('SACCO: ${l['schema_name'] ?? 'N/A'} · ${l['duration_months'] ?? 0} months @ ${l['calculated_interest_rate'] ?? 0}%',
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                        if (status == 'PENDING') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () => _resolveLoan(l['request_id'], 'APPROVE'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.emerald, foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () => _resolveLoan(l['request_id'], 'REJECT'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.coral, foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MEMBERSHIP MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

class _MembershipManagementScreen extends StatefulWidget {
  const _MembershipManagementScreen();

  @override
  State<_MembershipManagementScreen> createState() => _MembershipManagementScreenState();
}

class _MembershipManagementScreenState extends State<_MembershipManagementScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.client
          .from('sacco_membership_requests')
          .select('*')
          .order('created_at', ascending: false);
      if (mounted) setState(() { _requests = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String requestId, bool approve, Map<String, dynamic> request) async {
    await SupabaseService.resolveMembershipRequest(
      requestId: requestId,
      schemaName: request['schema_name'] ?? '',
      requestData: request,
      approve: approve,
    );
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? 'Membership approved' : 'Membership rejected'),
        backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _removeMember(String requestId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Membership'),
        content: Text('Remove $name permanently from this SACCO?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _removing = true);
    try {
      await SupabaseService.client.rpc('admin_remove_member', params: {'p_request_id': requestId});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Member removed'), backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _removing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Membership Requests', style: TextStyle(fontWeight: FontWeight.w700)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
          : _requests.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person_add_outlined, size: 48, color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
              const SizedBox(height: 12), Text('No membership requests', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final r = _requests[index];
                final status = r['status'] as String? ?? 'PENDING';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.cardColor,
                    border: Border.all(color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(80)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppConstants.violet.withAlpha(15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(child: Text((r['applicant_name'] as String? ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppConstants.violet, fontWeight: FontWeight.w800))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['applicant_name'] ?? '', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600)),
                                  Text(r['applicant_email'] ?? '', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (status == 'PENDING' ? AppConstants.amber : status == 'APPROVED' ? AppConstants.emerald : AppConstants.coral).withAlpha(15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status, style: TextStyle(
                                color: status == 'PENDING' ? AppConstants.amber : status == 'APPROVED' ? AppConstants.emerald : AppConstants.coral,
                                fontSize: 10, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: _removing
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                              onPressed: _removing ? null : () => _removeMember(r['request_id'], r['applicant_name'] ?? ''),
                              tooltip: 'Remove',
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('SACCO: ${r['schema_name'] ?? ''} · ${r['applicant_phone'] ?? ''}', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(140), fontSize: 12)),
                        if (status == 'PENDING') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38, child: ElevatedButton(
                                    onPressed: () => _resolve(r['request_id'], true, r),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.emerald, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SizedBox(
                                  height: 38, child: ElevatedButton(
                                    onPressed: () => _resolve(r['request_id'], false, r),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.coral, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════

class _AdminManagementScreen extends StatefulWidget {
  const _AdminManagementScreen();

  @override
  State<_AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<_AdminManagementScreen> {
  List<Map<String, dynamic>> _admins = [];
  bool _loading = true;
  final _emailCtrl = TextEditingController();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseService.client.from('super_admins').select('*').order('created_at', ascending: false);
      if (mounted) setState(() { _admins = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAdmin() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _adding = true);
    try {
      final userResult = await SupabaseService.client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (userResult == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No user found with that email'), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating,
          ));
          setState(() => _adding = false);
        }
        return;
      }

      final currentUser = SupabaseService.currentUser;
      await SupabaseService.client.from('super_admins').insert({
        'user_id': userResult['id'],
        'email': email,
        'role': 'SUPER_ADMIN',
        'created_by': currentUser?.id,
      });

      _emailCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Admin added successfully'), backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _adding = false);
  }

  Future<void> _removeAdmin(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Admin'),
        content: const Text('Are you sure you want to remove this admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.client.from('super_admins').delete().eq('id', id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Management', style: TextStyle(fontWeight: FontWeight.w700)), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.cardColor,
                    border: Border.all(color: AppConstants.coral.withAlpha(20)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New Admin', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Admin email',
                          prefixIcon: const Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity, height: 46,
                        child: ElevatedButton(
                          onPressed: _adding ? null : _addAdmin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.coral, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _adding
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Grant Admin Privileges', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Current Admins (${_admins.length})', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                ..._admins.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.cardColor,
                    border: Border.all(color: AppConstants.coral.withAlpha(15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.coral.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield, color: AppConstants.coral, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a['email'] ?? '', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text('Role: ${a['role'] ?? 'SUPER_ADMIN'}', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppConstants.coral, size: 20),
                        onPressed: () => _removeAdmin(a['id']),
                        tooltip: 'Remove admin',
                      ),
                    ],
                  ),
                )),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SACCO MEMBERS (view & remove members of a specific SACCO)
// ═══════════════════════════════════════════════════════════════════════════════

class _SaccoMembersScreen extends StatefulWidget {
  final Map<String, dynamic> sacco;
  const _SaccoMembersScreen({required this.sacco});

  @override
  State<_SaccoMembersScreen> createState() => _SaccoMembersScreenState();
}

class _SaccoMembersScreenState extends State<_SaccoMembersScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;
  bool _removing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final schema = widget.sacco['schema_name'] as String? ?? '';
      final data = await SupabaseService.client
          .from('sacco_membership_requests')
          .select('request_id, user_id, applicant_name, applicant_email, applicant_phone, status, created_at')
          .eq('schema_name', schema)
          .eq('status', 'APPROVED')
          .order('created_at', ascending: false);
      if (mounted) setState(() { _members = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeMember(String requestId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $name from this SACCO permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _removing = true);
    try {
      await SupabaseService.client.rpc('admin_remove_member', params: {'p_request_id': requestId});
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Member removed from SACCO'), backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _removing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saccoName = widget.sacco['sacco_name'] as String? ?? 'SACCO';
    return Scaffold(
      appBar: AppBar(
        title: Text(saccoName, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
          : _members.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.group_outlined, size: 48, color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
              const SizedBox(height: 12),
              Text('No approved members', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
            ]))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text('${_members.length} Approved Member${_members.length == 1 ? '' : 's'}',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(180), fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final m = _members[index];
                      final name = m['applicant_name'] as String? ?? 'Unknown';
                      final email = m['applicant_email'] as String? ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: theme.cardColor,
                          border: Border.all(color: AppConstants.emerald.withAlpha(20)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: _removing
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                onPressed: _removing ? null : () => _removeMember(m['request_id'], name),
                                tooltip: 'Remove from SACCO',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
