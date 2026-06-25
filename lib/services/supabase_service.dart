import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:makerere_fintech_app/features/auth/domain/entities/session_profile.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://rngowcdkpzudkplevaes.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuZ293Y2RrcHp1ZGtwbGV2YWVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MjYxNDIsImV4cCI6MjA5NzIwMjE0Mn0.wRmfLiTPsRBKHV2vk7WBjx3JtFiQMSwJ_BoI8QwCghs';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      publishableKey: _supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully');
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) =>
      client.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userMetadata,
    required Map<String, dynamic> appMetadata,
  }) =>
      client.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
      );

  static Future<void> signOut() => client.auth.signOut();

  static Session? get currentSession => client.auth.currentSession;
  static User? get currentUser => client.auth.currentUser;

  static SessionProfile buildProfileFromSession(AuthResponse response) {
    return SessionProfile.fromSupabaseUser(
      response.user!.toJson(),
      response.session!.accessToken,
    );
  }

  // ── SACCO Queries ──────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllSaccos() async {
    final response = await client
        .from('saccos')
        .select('sacco_id, sacco_name, registration_number, schema_name, created_at')
        .order('sacco_name');
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getSaccoTradingPatterns() async {
    final response = await client.rpc('get_sacco_trading_patterns');
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getPlatformMarketOverview() async {
    final response = await client.rpc('get_platform_market_overview');
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getSaccoLeaderboard() async {
    final response = await client.rpc('get_sacco_leaderboard');
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getSaccoDailyVolume({
    required String schemaName,
    int daysBack = 30,
  }) async {
    final response = await client.rpc('get_sacco_daily_volume', params: {
      'target_schema_name': schemaName,
      'days_back': daysBack,
    });
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getProductPerformance({
    required String schemaName,
  }) async {
    try {
      final List<dynamic> data = await client
          .from('tenant_financial_products')
          .select('product_id, product_name, interest_rate, minimum_balance');
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      final response = await client.rpc('get_product_performance', params: {
        'target_schema_name': schemaName,
      });
      return (response as List).cast<Map<String, dynamic>>();
    }
  }

  static Future<List<Map<String, dynamic>>> getMemberActivityPatterns({
    required String schemaName,
  }) async {
    final response = await client.rpc('get_member_activity_patterns', params: {
      'target_schema_name': schemaName,
    });
    return (response as List).cast<Map<String, dynamic>>();
  }

  // ── Tenant Schema Queries ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTenantTransactions({
    required String schemaName,
    int limit = 50,
  }) async {
    try {
      final response = await client
          .from('$schemaName.transactions')
          .select('*, users(full_name, phone_number), products(product_name)')
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (_) {
      final response = await client
          .from('sacco_transactions')
          .select('*, profiles!inner(full_name, email)')
          .eq('schema_name', schemaName.trim().toLowerCase())
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).map((t) => <String, dynamic>{
        'transaction_id': t['transaction_id'],
        'user_id': t['user_id'],
        'amount': t['amount'],
        'transaction_type': t['transaction_type'],
        'status': t['status'],
        'created_at': t['created_at'],
        'reference_id': t['reference_id'],
        'users': {
          'full_name': t['profiles']?['full_name'],
          'phone_number': t['profiles']?['phone_number'],
        },
      }).toList();
    }
  }

  static Future<List<Map<String, dynamic>>> getTenantProducts({
    required String schemaName,
  }) async {
    try {
      final response = await client
          .from('$schemaName.products')
          .select('*')
          .order('product_name');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (_) {
      final response = await client
          .from('tenant_financial_products')
          .select('*')
          .order('product_name');
      return (response as List).cast<Map<String, dynamic>>();
    }
  }

  static Future<List<Map<String, dynamic>>> getTenantMembers({
    required String schemaName,
  }) async {
    try {
      final response = await client
          .from('$schemaName.users')
          .select('*')
          .order('full_name');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (_) {
      final response = await client
          .from('sacco_membership_requests')
          .select('user_id, applicant_name, applicant_email, applicant_phone, status')
          .eq('schema_name', schemaName.trim().toLowerCase())
          .eq('status', 'APPROVED')
          .order('created_at', ascending: false);
      return (response as List).map((r) => <String, dynamic>{
        'id': r['user_id'],
        'full_name': r['applicant_name'],
        'email': r['applicant_email'],
        'phone_number': r['applicant_phone'],
        'status': 'ACTIVE',
      }).toList();
    }
  }

  static Future<void> insertTenantTransaction({
    required String schemaName,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await client.from('$schemaName.transactions').insert(payload);
    } catch (_) {
      await client.from('tenant_transactions').insert({
        'user_id': payload['user_id'] ?? currentUser?.id,
        'product_id': payload['product_id'],
        'amount': payload['amount'],
        'transaction_type': payload['transaction_type'],
        'status': 'COMPLETED',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    try {
      await client.from('sacco_transactions').insert({
        'user_id': payload['user_id'] ?? currentUser?.id,
        'schema_name': schemaName.trim().toLowerCase(),
        'account_type': 'SAVINGS',
        'transaction_type': payload['transaction_type'] ?? 'DEPOSIT',
        'amount': payload['amount'],
        'reference_id': 'DEP-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'SUCCESSFUL',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── Real-Time Ledger Transactions Payment Handlers ─────────────────────────

  /// Records verified financial transaction entries cleanly into the master ledger grid.
  static Future<void> recordLedgerTransaction({
    required String schemaName,
    required Map<String, dynamic> payload,
  }) async {
    await client.from('sacco_transactions').insert({
      'sacco_id': payload['sacco_id'],
      'schema_name': schemaName.trim().toLowerCase(),
      'user_id': payload['user_id'],
      'account_type': payload['account_type'] ?? 'SAVINGS',
      'transaction_type': payload['transaction_type'],
      'amount': payload['amount'],
      'reference_id': payload['reference_id'],
      'status': 'SUCCESSFUL',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ── Membership Processing ──────────────────────────────────────────────────

  static Future<void> submitMembershipRequest({
    required String saccoId,
    required String schemaName,
    required String fullName,
    required String phone,
    required String email,
    String? userId,
  }) async {
    final runtimeUser = client.auth.currentUser ?? client.auth.currentSession?.user;
    final String targetUserId = userId ?? runtimeUser?.id ?? 'guest_test_user_id';

    await client.from('sacco_membership_requests').insert({
      'sacco_id': saccoId,
      'schema_name': schemaName.trim().toLowerCase(),
      'user_id': targetUserId,
      'applicant_name': fullName,
      'applicant_phone': phone,
      'applicant_email': email.trim().toLowerCase(),
      'status': 'PENDING',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getMembershipRequests({
    required String schemaName,
  }) async {
    final response = await client
        .from('sacco_membership_requests')
        .select('*')
        .eq('schema_name', schemaName.trim().toLowerCase()) // ⚡ FIXED: Clean syntax chain
        .order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<void> resolveMembershipRequest({
    required String requestId,
    required String schemaName,
    required Map<String, dynamic> requestData,
    required bool approve,
  }) async {
    final String targetStatus = approve ? 'APPROVED' : 'REJECTED';

    await client
        .from('sacco_membership_requests')
        .update({'status': targetStatus, 'updated_at': DateTime.now().toIso8601String()})
        .eq('request_id', requestId);

    if (approve) {
      try {
        await client.from('$schemaName.users').insert({
          'id': requestData['user_id'],
          'full_name': requestData['applicant_name'],
          'phone_number': requestData['applicant_phone'],
          'email': requestData['applicant_email'],
          'status': 'ACTIVE',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  static Future<void> toggleMemberSuspension({
    required String schemaName,
    required String userId,
    required String currentStatus,
  }) async {
    final String targetStatus = currentStatus == 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';

    try {
      await client.rpc('toggle_tenant_member_status', params: {
        'target_schema_name': schemaName,
        'target_user_id': userId,
        'new_status': targetStatus,
      });
    } catch (_) {
      await client.rpc('toggle_member_ledger_freeze', params: {
        'p_schema_name': schemaName,
        'p_user_id': userId,
        'p_current_status': currentStatus,
      });
    }
  }

  // ── Credit Management & Loans ──────────────────────────────────────────────

  static Future<void> submitLoanRequest({
    required String saccoId,
    required String schemaName,
    required double principal,
    required int months,
    required double rate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("Authorization session context missing.");

    try {
      await client.from('sacco_loan_requests').insert({
        'sacco_id': saccoId,
        'schema_name': schemaName,
        'user_id': user.id,
        'applicant_name': user.userMetadata?['full_name'] ?? 'SACCO Member',
        'principal_amount': principal,
        'duration_months': months,
        'calculated_interest_rate': rate,
        'status': 'PENDING',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      await client.from('tenant_loans').insert({
        'user_id': user.id,
        'amount_requested': principal,
        'interest_rate': rate,
        'repayment_period_months': months,
        'status': 'SUBMITTED',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<List<Map<String, dynamic>>> getSaccoLoanRequests({
    required String schemaName,
  }) async {
    try {
      final response = await client
          .from('sacco_loan_requests')
          .select('*')
          .eq('schema_name', schemaName)
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (_) {
      final response = await client
          .from('tenant_loans')
          .select('*, profiles(full_name, email)')
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    }
  }

  static Future<List<Map<String, dynamic>>> getGlobalAuditOverview() async {
    final response = await client.rpc('get_global_audit_overview');
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<bool> isSuperAdmin() async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    try {
      final result = await client.rpc('is_super_admin');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verifyAdminPrivileges({required String schemaName}) async {
    final user = client.auth.currentUser ?? client.auth.currentSession?.user;
    if (user == null || user.email == null) return false;

    if (await isSuperAdmin()) return true;

    try {
      final response = await client
          .from('sacco_admins')
          .select()
          .eq('schema_name', schemaName.trim().toLowerCase())
          .eq('admin_email', user.email!.trim().toLowerCase())
          .maybeSingle();

      if (response != null) return true;

      final rpcResponse = await client.rpc('check_sacco_admin_by_email', params: {
        'target_schema_name': schemaName,
        'p_user_email': user.email!,
      });
      return rpcResponse as bool;
    } catch (_) {
      return false;
    }
  }

  // ── Super Admin Operations ─────────────────────────────────────────────

  static Future<void> adminDeleteUser(String userId) =>
      client.rpc('admin_delete_user', params: {'p_user_id': userId});

  static Future<void> adminDeleteSacco(String saccoId) =>
      client.rpc('admin_delete_sacco', params: {'p_sacco_id': saccoId});

  static Future<void> adminRemoveMember(String requestId) =>
      client.rpc('admin_remove_member', params: {'p_request_id': requestId});

  static Future<bool> checkMembershipStatus({required String schemaName}) async {
    final user = currentUser;
    if (user == null) return false;

    if (await isSuperAdmin()) return true;

    try {
      final response = await client
          .from('sacco_membership_requests')
          .select('status')
          .eq('schema_name', schemaName.trim().toLowerCase())
          .eq('user_id', user.id)
          .eq('status', 'APPROVED')
          .maybeSingle();

      if (response != null) return true;

      final rpcResponse = await client.rpc('check_is_sacco_member', params: {
        'target_schema_name': schemaName,
        'target_user_id': user.id,
      });
      return rpcResponse as bool;
    } catch (_) {
      return false;
    }
  }

  // ── User Transaction Chain (Blockchain Audit Ledger) ─────────────────────

  /// After recording a sacco_transaction, call this to append a block to the user's chain.
  static Future<void> buildUserChainBlock({
    required String transactionId,
    required String saccoId,
    required String schemaName,
    required String transactionType,
    required double amount,
    required String referenceId,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await client.rpc('build_user_chain_block', params: {
      'p_user_id': user.id,
      'p_transaction_id': transactionId,
      'p_sacco_id': saccoId,
      'p_schema_name': schemaName,
      'p_transaction_type': transactionType,
      'p_amount': amount,
      'p_reference_id': referenceId,
    });
  }

  /// Returns every block in a user's chain, ordered from genesis to latest.
  static Future<List<Map<String, dynamic>>> getUserChain({
    required String userId,
  }) async {
    final response = await client.rpc('get_user_chain', params: {
      'p_user_id': userId,
    });
    return (response as List).cast<Map<String, dynamic>>();
  }

  /// Verifies the full chain integrity for a user (prev_hash linkage).
  static Future<bool> verifyUserChain({required String userId}) async {
    final result = await client.rpc('verify_user_chain', params: {
      'p_user_id': userId,
    });
    return result == true;
  }

  /// Looks up a hash (block_hash, prev_hash, or merkle_root) and returns
  /// the matching block plus full chain integrity status for that user.
  static Future<Map<String, dynamic>?> verifyChainHash({required String hash}) async {
    try {
      final result = await client.rpc('verify_chain_hash', params: {
        'p_hash': hash,
      });
      if (result is List && result.isNotEmpty) {
        return Map<String, dynamic>.from(result.first);
      }
      return null;
    } catch (e) {
      // Re-throw with more context so the UI can display it
      throw Exception('RPC verify_chain_hash failed: $e');
    }
  }

  /// Returns summary stats: total blocks, volume, integrity, timestamps.
  static Future<Map<String, dynamic>?> getUserChainSummary({
    required String userId,
  }) async {
    final result = await client.rpc('get_user_chain_summary', params: {
      'p_user_id': userId,
    });
    if (result is List && result.isNotEmpty) {
      return Map<String, dynamic>.from(result.first);
    }
    return null;
  }

  /// Records a transaction AND builds its chain block in one call.
  static Future<void> recordTransactionAndBuildChain({
    required String schemaName,
    required String saccoId,
    required Map<String, dynamic> payload,
  }) async {
    // 1) Insert the sacco_transaction
    final txResponse = await client.from('sacco_transactions').insert({
      'sacco_id': saccoId,
      'schema_name': schemaName.trim().toLowerCase(),
      'user_id': payload['user_id'],
      'account_type': payload['account_type'] ?? 'SAVINGS',
      'transaction_type': payload['transaction_type'],
      'amount': payload['amount'],
      'reference_id': payload['reference_id'],
      'status': 'SUCCESSFUL',
      'created_at': DateTime.now().toIso8601String(),
    }).select('transaction_id').maybeSingle();

    if (txResponse != null) {
      // 2) Build the chain block
      await buildUserChainBlock(
        transactionId: txResponse['transaction_id'].toString(),
        saccoId: saccoId,
        schemaName: schemaName,
        transactionType: payload['transaction_type'] ?? 'DEPOSIT',
        amount: (payload['amount'] as num).toDouble(),
        referenceId: payload['reference_id'] ?? '',
      );
    }
  }
}