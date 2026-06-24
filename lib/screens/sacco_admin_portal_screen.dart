import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

class SaccoAdminPortalScreen extends StatefulWidget {
  final String saccoName;
  final String schemaName;

  const SaccoAdminPortalScreen({
    super.key,
    required this.saccoName,
    required this.schemaName,
  });

  @override
  State<SaccoAdminPortalScreen> createState() => _SaccoAdminPortalScreenState();
}

class _SaccoAdminPortalScreenState extends State<SaccoAdminPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getMembershipRequests(schemaName: widget.schemaName).catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.getTenantMembers(schemaName: widget.schemaName).catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.getSaccoLoanRequests(schemaName: widget.schemaName).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(results[0]);
          _members = List<Map<String, dynamic>>.from(results[1]);
          _loans = List<Map<String, dynamic>>.from(results[2]);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _confirmAction(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(message, style: TextStyle(fontSize: 14, color: Theme.of(ctx).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.emerald,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleAction(Map<String, dynamic> request, bool approve) async {
    final ok = await _confirmAction(
      approve ? 'Approve Membership' : 'Reject Membership',
      '${approve ? 'Approve' : 'Reject'} ${request['applicant_name'] ?? 'this applicant'} for ${widget.saccoName}?',
    );
    if (!ok) return;

    try {
      await SupabaseService.resolveMembershipRequest(
        requestId: request['request_id'] ?? request['id'] ?? '',
        schemaName: widget.schemaName,
        requestData: request,
        approve: approve,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${approve ? 'Approved' : 'Rejected'} ${request['applicant_name'] ?? ''}'),
          backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _loadAdminData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _handleLoanAction(String loanId, String action, Map<String, dynamic> loan) async {
    final statusMap = {'APPROVE': 'Approve', 'REJECT': 'Reject', 'DISBURSE': 'Disburse'};
    final ok = await _confirmAction(
      '${statusMap[action] ?? action} Loan',
      '${statusMap[action] ?? action} UGX ${(loan['principal_amount'] as num?)?.toStringAsFixed(0) ?? '0'} loan for ${loan['applicant_name'] ?? 'this borrower'}?',
    );
    if (!ok) return;

    try {
      final txHash = action == 'APPROVE' || action == 'DISBURSE'
          ? '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}${loanId.substring(0, 8)}'
          : null;

      await SupabaseService.client.rpc('resolve_sacco_loan_request', params: {
        'p_loan_id': loanId,
        'p_action': action,
        'p_blockchain_hash': txHash,
      });

      if (action == 'DISBURSE') {
        final user = SupabaseService.currentUser;
        await SupabaseService.recordLedgerTransaction(
          schemaName: widget.schemaName,
          payload: {
            'sacco_id': loan['sacco_id'],
            'user_id': loan['user_id'] ?? user?.id,
            'account_type': 'LOAN',
            'transaction_type': 'LOAN_DISBURSEMENT',
            'amount': loan['principal_amount'] ?? 0,
            'reference_id': 'LND-${DateTime.now().millisecondsSinceEpoch}',
          },
        );
        if (txHash != null) {
          try {
            await SupabaseService.client.from('blockchain_audit_footprints').insert({
              'transaction_id': loanId,
              'merkle_root': txHash,
              'blockchain_network': 'MAKERERE_SACCO_CHAIN',
              'smart_contract_address': '0x0000000000000000000000000000000000000000',
              'blockchain_tx_hash': txHash,
            });
          } catch (_) {}
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Loan ${action.toLowerCase()}d successfully'),
          backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _loadAdminData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _toggleSuspension(Map<String, dynamic> member) async {
    final currentStatus = member['status'] ?? 'ACTIVE';
    final targetStatus = currentStatus == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    final ok = await _confirmAction(
      targetStatus == 'SUSPENDED' ? 'Suspend Member' : 'Activate Member',
      '${targetStatus == 'SUSPENDED' ? 'Suspend' : 'Activate'} ${member['full_name'] ?? 'this member'}?',
    );
    if (!ok) return;

    try {
      await SupabaseService.toggleMemberSuspension(
        schemaName: widget.schemaName,
        userId: member['id'] ?? '',
        currentStatus: currentStatus,
      );
      _loadAdminData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final ok = await _confirmAction(
      'Remove Member',
      'Remove ${member['full_name'] ?? 'this member'} from ${widget.saccoName}? This action cannot be undone.',
    );
    if (!ok) return;

    try {
      await SupabaseService.client
          .from('sacco_membership_requests')
          .update({'status': 'REMOVED', 'updated_at': DateTime.now().toIso8601String()})
          .eq('schema_name', widget.schemaName.trim().toLowerCase())
          .eq('user_id', member['id'] ?? '')
          .eq('status', 'APPROVED');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${member['full_name'] ?? 'Member'} removed from SACCO'),
          backgroundColor: AppConstants.emerald, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        _loadAdminData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [theme.scaffoldBackgroundColor, isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme),
              _buildTabBar(theme),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
                    : RefreshIndicator(
                        onRefresh: _loadAdminData,
                        color: AppConstants.emerald,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRequestsTab(theme),
                            _buildMembersTab(theme),
                            _buildLoansTab(theme),
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

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: theme.textTheme.bodyLarge?.color),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: AppConstants.emerald.withAlpha(40), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Control', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(widget.saccoName, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statChip(theme, Icons.person_add_outlined, '${_requests.where((r) => r['status'] == 'PENDING').length} pending', AppConstants.amber),
              const SizedBox(width: 8),
              _statChip(theme, Icons.people_outline, '${_members.length} members', AppConstants.emerald),
              const SizedBox(width: 8),
              _statChip(theme, Icons.request_quote_outlined, '${_loans.where((l) => l['status'] == 'PENDING').length} loans', AppConstants.cyan),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statChip(ThemeData theme, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    final pendingRequests = _requests.where((r) => r['status'] == 'PENDING').length;
    final pendingLoans = _loans.where((l) => l['status'] == 'PENDING').length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: (theme.brightness == Brightness.dark ? const Color(0xFF0F1A2E) : const Color(0xFFF0F2F5)).withAlpha(180),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withAlpha(160),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.all(4),
        tabs: [
          Tab(text: pendingRequests > 0 ? 'Requests ($pendingRequests)' : 'Requests'),
          Tab(text: 'Members'),
          Tab(text: pendingLoans > 0 ? 'Credit ($pendingLoans)' : 'Credit Desk'),
        ],
      ),
    );
  }

  // ── REQUESTS TAB ──────────────────────────────────────────────────────────

  Widget _buildRequestsTab(ThemeData theme) {
    if (_requests.isEmpty) {
      return _emptyState(theme, Icons.inbox_rounded, 'No membership requests', 'Pending applications will appear here');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _requests.length,
      itemBuilder: (context, index) => _requestCard(theme, _requests[index]),
    );
  }

  Widget _requestCard(ThemeData theme, Map<String, dynamic> req) {
    final status = req['status'] as String? ?? 'PENDING';
    final isPending = status == 'PENDING';
    final name = req['applicant_name'] as String? ?? 'Applicant';
    final email = req['applicant_email'] as String? ?? '';
    final phone = req['applicant_phone'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.cardColor,
        border: Border.all(color: (isPending ? AppConstants.amber : AppConstants.emerald).withAlpha(25)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPending ? [AppConstants.amber.withAlpha(180), AppConstants.amber.withAlpha(60)] : [AppConstants.emerald, AppConstants.emeraldDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 12, color: theme.textTheme.bodyMedium?.color?.withAlpha(100)),
                  const SizedBox(width: 6),
                  Text(phone, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(140), fontSize: 12)),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAction(req, true),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.emerald,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAction(req, false),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.coral,
                          side: BorderSide(color: AppConstants.coral.withAlpha(120)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
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
  }

  // ── MEMBERS TAB ───────────────────────────────────────────────────────────

  Widget _buildMembersTab(ThemeData theme) {
    if (_members.isEmpty) {
      return _emptyState(theme, Icons.people_outline, 'No members yet', 'Approved members will appear here');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _members.length,
      itemBuilder: (context, index) => _memberCard(theme, _members[index]),
    );
  }

  Widget _memberCard(ThemeData theme, Map<String, dynamic> member) {
    final isSuspended = member['status'] == 'SUSPENDED';
    final name = member['full_name'] as String? ?? 'Unknown';
    final email = member['email'] as String? ?? '';
    final phone = member['phone_number'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(color: (isSuspended ? AppConstants.amber : AppConstants.emerald).withAlpha(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSuspended
                      ? [Colors.grey.withAlpha(150), Colors.grey.withAlpha(80)]
                      : [AppConstants.emerald, AppConstants.emeraldDark],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20))),
                  if (isSuspended)
                    Positioned(
                      right: -2, top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppConstants.amber, shape: BoxShape.circle),
                        child: const Icon(Icons.pause, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14))),
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSuspended ? AppConstants.amber : AppConstants.emerald,
                          boxShadow: [BoxShadow(color: (isSuspended ? AppConstants.amber : AppConstants.emerald).withAlpha(60), blurRadius: 6)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                  if (phone.isNotEmpty)
                    Text(phone, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(120), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleSuspension(member),
                    icon: Icon(isSuspended ? Icons.lock_open_rounded : Icons.lock_outline, size: 12),
                    label: Text(isSuspended ? 'Activate' : 'Suspend', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isSuspended ? AppConstants.emerald : AppConstants.amber,
                      side: BorderSide(color: (isSuspended ? AppConstants.emerald : AppConstants.amber).withAlpha(120)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _removeMember(member),
                    icon: const Icon(Icons.person_remove_outlined, size: 12),
                    label: const Text('Remove', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.coral,
                      side: BorderSide(color: AppConstants.coral.withAlpha(120)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── LOANS TAB ─────────────────────────────────────────────────────────────

  Widget _buildLoansTab(ThemeData theme) {
    if (_loans.isEmpty) {
      return _emptyState(theme, Icons.request_quote_outlined, 'No loan applications', 'Pending applications will appear here');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _loans.length,
      itemBuilder: (context, index) => _loanCard(theme, _loans[index]),
    );
  }

  Widget _loanCard(ThemeData theme, Map<String, dynamic> loan) {
    final status = loan['status'] as String? ?? 'PENDING';
    final principal = (loan['principal_amount'] as num?)?.toDouble() ?? 0;
    final rate = (loan['calculated_interest_rate'] as num?)?.toDouble() ?? 0;
    final months = (loan['duration_months'] as num?)?.toInt() ?? 0;
    final interest = principal * rate / 100;
    final totalRepayment = principal + interest;
    final monthlyPayment = months > 0 ? totalRepayment / months : 0;
    final name = loan['applicant_name'] as String? ?? 'Borrower';
    final Color statusColor = status == 'APPROVED' || status == 'DISBURSED'
        ? AppConstants.emerald
        : status == 'PENDING' ? AppConstants.amber : AppConstants.coral;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.cardColor,
        border: Border.all(color: statusColor.withAlpha(25)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  statusColor.withAlpha(8),
                  statusColor.withAlpha(2),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('$months months @ ${rate.toStringAsFixed(1)}% APR', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12)),
                        ],
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _amountDisplay(theme, 'Principal', principal, AppConstants.emerald),
                    const SizedBox(width: 16),
                    _amountDisplay(theme, 'Interest', interest, AppConstants.amber),
                    const SizedBox(width: 16),
                    _amountDisplay(theme, 'Total', totalRepayment, AppConstants.cyan),
                  ],
                ),
                if (monthlyPayment > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.violet.withAlpha(10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppConstants.violet.withAlpha(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month, size: 12, color: AppConstants.violet),
                        const SizedBox(width: 6),
                        Text('UGX ${monthlyPayment.toStringAsFixed(0)}/mo', style: const TextStyle(color: AppConstants.violet, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.dividerColor.withAlpha(30))),
            ),
            child: status == 'PENDING'
                ? Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleLoanAction(loan['request_id'] ?? loan['loan_id'] ?? '', 'APPROVE', loan),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.emerald, foregroundColor: Colors.black, elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleLoanAction(loan['request_id'] ?? loan['loan_id'] ?? '', 'REJECT', loan),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConstants.coral,
                              side: BorderSide(color: AppConstants.coral.withAlpha(120)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : status == 'APPROVED'
                    ? SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleLoanAction(loan['request_id'] ?? loan['loan_id'] ?? '', 'DISBURSE', loan),
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                          label: const Text('Blockchain Disbursement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.cyan, foregroundColor: Colors.black, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      )
                    : status == 'DISBURSED'
                        ? Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppConstants.emerald, size: 18),
                              const SizedBox(width: 8),
                              Text('Disbursed — anchored to blockchain', style: TextStyle(color: AppConstants.emerald, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          )
                        : Row(
                            children: [
                              const Icon(Icons.cancel_outlined, color: AppConstants.coral, size: 18),
                              const SizedBox(width: 8),
                              Text('Rejected', style: TextStyle(color: AppConstants.coral, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _amountDisplay(ThemeData theme, String label, double amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(140), fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('UGX ${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }

  // ── SHARED WIDGETS ────────────────────────────────────────────────────────

  Widget _statusBadge(String status) {
    final Color color = status == 'APPROVED' || status == 'DISBURSED'
        ? AppConstants.emerald
        : status == 'PENDING' ? AppConstants.amber : AppConstants.coral;
    final String label = status == 'APPROVED' ? 'Approved' : status == 'DISBURSED' ? 'Disbursed' : status == 'REJECTED' ? 'Rejected' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withAlpha(18), color.withAlpha(8)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: color == AppConstants.emerald
                  ? [BoxShadow(color: AppConstants.emerald.withAlpha(100), blurRadius: 4)]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.emerald.withAlpha(8),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 48, color: AppConstants.emerald.withAlpha(80)),
            ),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
