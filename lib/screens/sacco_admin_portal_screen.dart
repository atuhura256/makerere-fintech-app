import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
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
        SupabaseService.getMembershipRequests(schemaName: widget.schemaName)
            .catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.getTenantMembers(schemaName: widget.schemaName)
            .catchError((_) => <Map<String, dynamic>>[]),
        SupabaseService.getSaccoLoanRequests(schemaName: widget.schemaName)
            .catchError((_) => <Map<String, dynamic>>[]),
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

  Future<void> _handleAction(Map<String, dynamic> request, bool approve) async {
    setState(() {
      _requests = _requests.map((r) {
        if (r['request_id'] == request['request_id']) {
          return {...r, 'status': approve ? 'APPROVED' : 'REJECTED'};
        }
        return r;
      }).toList();
    });

    try {
      await SupabaseService.resolveMembershipRequest(
        requestId: request['request_id'] ?? request['id'] ?? '',
        schemaName: widget.schemaName,
        requestData: request,
        approve: approve,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✔ Application successfully ${approve ? "approved" : "rejected"}.'),
            backgroundColor: approve ? AppConstants.emerald : Colors.orangeAccent,
          ),
        );
        _loadAdminData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
        _loadAdminData();
      }
    }
  }

  Future<void> _handleLoanAction(String loanId, String action) async {
    try {
      const mockTxHash = "0x7d83f2a1b0c9e8d7f6a5b4c3d2e1f00a9b8c7d6e5f4a3b2c1d0f9e8a7b6c5d4e";

      await SupabaseService.client.rpc('resolve_sacco_loan_request', params: {
        'p_loan_id': loanId,
        'p_action': action,
        'p_blockchain_hash': action == 'APPROVE' || action == 'DISBURSE' ? mockTxHash : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✔ Credit line updated to $action state successfully.'), backgroundColor: AppConstants.emerald)
        );
        _loadAdminData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loan mutation fault: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _toggleSuspension(Map<String, dynamic> member) async {
    final String currentStatus = member['status'] ?? 'ACTIVE';
    final String targetStatus = currentStatus == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';

    setState(() {
      _members = _members.map((m) {
        if (m['id'] == member['id']) return {...m, 'status': targetStatus};
        return m;
      }).toList();
    });

    try {
      await SupabaseService.toggleMemberSuspension(
        schemaName: widget.schemaName,
        userId: member['id'] ?? '',
        currentStatus: currentStatus,
      );
      _loadAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
        _loadAdminData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg : AppConstants.lightBg,
      appBar: AppBar(
        title: Text('${widget.saccoName} Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.emerald,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppConstants.emerald,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Requests'),
            Tab(text: 'Members'),
            Tab(text: 'Credit Desk'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.emerald))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsTab(),
          _buildMembersTab(),
          _buildLoansTab(),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    final theme = Theme.of(context);
    if (_requests.isEmpty) {
      return Center(child: Text('No membership requisitions filed yet.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        final bool isPending = req['status'] == 'PENDING';

        return BlockchainCard(
          hasAccentBar: true,
          accentColor: isPending ? AppConstants.amber : AppConstants.emerald,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(req['applicant_name'] ?? 'Anonymous Applicant', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 15)),
                  BlockchainStatusChip(status: req['status'] ?? 'PENDING'),
                ],
              ),
              const SizedBox(height: 6),
              _infoRow(Icons.email_outlined, '${req['applicant_email'] ?? ''}', theme),
              const SizedBox(height: 2),
              _infoRow(Icons.phone_outlined, '${req['applicant_phone'] ?? ''}', theme),
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAction(req, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.emerald,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleAction(req, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab() {
    final theme = Theme.of(context);
    if (_members.isEmpty) {
      return Center(child: Text('No active ledger members tracked yet.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final bool isFrozen = member['status'] == 'SUSPENDED';

        return BlockchainCard(
          hasAccentBar: true,
          accentColor: isFrozen ? AppConstants.amber : AppConstants.emerald,
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['full_name'] ?? 'Active User Token', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    _infoRow(Icons.email_outlined, '${member['email'] ?? ''}', theme),
                    const SizedBox(height: 2),
                    _infoRow(Icons.phone_outlined, '${member['phone_number'] ?? ''}', theme),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _toggleSuspension(member),
                icon: Icon(isFrozen ? Icons.lock_open_outlined : Icons.lock_outline, size: 14),
                label: Text(isFrozen ? 'Unfreeze' : 'Freeze Account', style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isFrozen ? AppConstants.emerald : Colors.orangeAccent,
                  side: BorderSide(color: isFrozen ? AppConstants.emerald : Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoansTab() {
    final theme = Theme.of(context);
    if (_loans.isEmpty) {
      return Center(child: Text('No credit application claims filed yet.', style: TextStyle(color: theme.textTheme.bodyMedium?.color)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loans.length,
      itemBuilder: (context, index) {
        final loan = _loans[index];
        final String loanId = loan['loan_id'] ?? '';
        final String currentStatus = loan['status'] ?? 'PENDING';

        return BlockchainCard(
          hasAccentBar: true,
          accentColor: currentStatus == 'APPROVED' || currentStatus == 'DISBURSED'
              ? AppConstants.emerald
              : currentStatus == 'PENDING' ? AppConstants.amber : AppConstants.coral,
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loan['applicant_name'] ?? 'Borrower Profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 14)),
                  BlockchainStatusChip(status: currentStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text('Principal Requested: UGX ${loan['principal_amount']}', style: const TextStyle(color: AppConstants.emerald, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text('Repayment Period: ${loan['duration_months']} Months @ ${loan['calculated_interest_rate']}% APR', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),

              if (loan['blockchain_tx_hash'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.cyan.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.cyan.withAlpha(20), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_outlined, color: AppConstants.cyan, size: 12),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Anchor: ${loan['blockchain_tx_hash']}', overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppConstants.cyan, fontFamily: 'monospace', fontSize: 10))),
                    ],
                  ),
                ),
              ],

              if (currentStatus == 'PENDING') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleLoanAction(loanId, 'APPROVE'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.emerald,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Approve Loan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleLoanAction(loanId, 'REJECT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Decline Claims', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ] else if (currentStatus == 'APPROVED') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLoanAction(loanId, 'DISBURSE'),
                    icon: const Icon(Icons.account_balance_wallet_outlined, size: 14),
                    label: const Text('Execute Blockchain Disbursement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.cyan,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 12, color: theme.textTheme.bodyMedium?.color?.withAlpha(120)),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
      ],
    );
  }
}
