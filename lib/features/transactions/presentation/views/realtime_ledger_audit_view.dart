import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/widgets/glass_bottom_nav_bar.dart';

class RealtimeLedgerAuditView extends StatefulWidget {
  const RealtimeLedgerAuditView({super.key});

  @override
  State<RealtimeLedgerAuditView> createState() => _RealtimeLedgerAuditViewState();
}

class _RealtimeLedgerAuditViewState extends State<RealtimeLedgerAuditView> {
  List<Map<String, dynamic>> _chain = [];
  Map<String, dynamic>? _summary;
  bool _loading = true;
  bool _chainValid = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final user = SupabaseService.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final results = await Future.wait([
        SupabaseService.getUserChain(userId: user.id),
        SupabaseService.verifyUserChain(userId: user.id),
        SupabaseService.getUserChainSummary(userId: user.id),
      ]);

      if (mounted) {
        setState(() {
          _chain = (results[0] as List).cast<Map<String, dynamic>>();
          _chainValid = results[1] as bool;
          _summary = results[2] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openVerifySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VerifyHashSheet(),
    );
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? AppConstants.darkBg : AppConstants.lightBg,
                  isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _load,
              color: AppConstants.emerald,
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator(color: AppConstants.emerald))
                        : _chain.isEmpty
                            ? _buildEmptyState(context)
                            : _buildChainList(context),
                  ),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
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
          border: Border.all(color: AppConstants.emerald.withAlpha(25)),
          boxShadow: [
            BoxShadow(color: AppConstants.emerald.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppConstants.emerald.withAlpha(40), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Immutable Audit Trail',
                        style: TextStyle(fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _chainValid ? AppConstants.emerald.withAlpha(12) : AppConstants.coral.withAlpha(12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _chainValid
                              ? '${_chain.length} blocks · SHA-256 anchored'
                              : 'Chain Integrity Compromised',
                          style: TextStyle(
                            color: _chainValid ? AppConstants.emerald : AppConstants.coral,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Verify Hash Button ──
                GestureDetector(
                  onTap: _openVerifySheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppConstants.violet.withAlpha(30), AppConstants.chainBlue.withAlpha(30)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppConstants.violet.withAlpha(40)),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppConstants.violet, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _chainValid ? AppConstants.emerald.withAlpha(15) : AppConstants.coral.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _chainValid ? Icons.verified_rounded : Icons.error_outline_rounded,
                    color: _chainValid ? AppConstants.emerald : AppConstants.coral,
                    size: 20,
                  ),
                ),
              ],
            ),
            if (_summary != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _statPill(context, 'Blocks', '${_summary!['total_blocks'] ?? 0}', AppConstants.emerald),
                  const SizedBox(width: 8),
                  _statPill(context, 'Volume', _formatCompact(_summary!['total_volume'] ?? 0), AppConstants.cyan),
                  const SizedBox(width: 8),
                  _statPill(context, 'Integrity', _chainValid ? 'PASS' : 'FAIL', _chainValid ? AppConstants.emerald : AppConstants.coral),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statPill(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: color.withAlpha(160), fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppConstants.emerald.withAlpha(10), AppConstants.cyan.withAlpha(8)],
              ),
            ),
            child: const Icon(Icons.link_rounded, size: 48, color: AppConstants.emerald),
          ),
          const SizedBox(height: 20),
          Text('No blocks yet', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            'Your blockchain chain will appear here\nonce you make your first transaction.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(140), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChainList(BuildContext context) {
    final reversed = _chain.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: reversed.length,
      itemBuilder: (context, index) {
        final block = reversed[index];
        final isLatest = index == 0;
        final isGenesis = block['block_index'] == 0;
        return _ChainBlock(
          block: block,
          isLatest: isLatest,
          isGenesis: isGenesis,
          totalBlocks: _chain.length,
        );
      },
    );
  }

  String _formatCompact(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }
}

// ─── Verify Hash Bottom Sheet ──────────────────────────────────────────────

class _VerifyHashSheet extends StatefulWidget {
  const _VerifyHashSheet();

  @override
  State<_VerifyHashSheet> createState() => _VerifyHashSheetState();
}

class _VerifyHashSheetState extends State<_VerifyHashSheet> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Map<String, dynamic>? _result;
  bool _verifying = false;
  bool _searched = false;
  String _verifySource = '';
  String _errorMessage = '';
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final hash = _controller.text.trim();
    if (hash.isEmpty) return;

    setState(() {
      _verifying = true;
      _result = null;
      _searched = false;
      _verifySource = '';
      _errorMessage = '';
    });
    _animController.repeat(reverse: true);

    try {
      // 1) Try server-side verification first
      var result = await SupabaseService.verifyChainHash(hash: hash);
      _verifySource = 'server';

      // 2) If not found server-side, try client-side verification
      if (result == null || result['found'] != true) {
        final clientResult = await _clientSideVerify(hash);
        if (clientResult != null && clientResult['found'] == true) {
          result = clientResult;
          _verifySource = 'client';
        } else {
          result ??= clientResult;
        }
      }

      _animController.stop();
      _animController.reset();
      if (mounted) {
        setState(() {
          _result = result;
          _verifying = false;
          _searched = true;
        });
      }
    } catch (e) {
      // Server RPC failed, try client-side
      try {
        final clientResult = await _clientSideVerify(hash);
        _animController.stop();
        _animController.reset();
        if (mounted) {
          setState(() {
            _result = clientResult;
            _verifySource = 'client';
            _verifying = false;
            _searched = true;
            if (clientResult == null || clientResult['found'] != true) {
              _errorMessage = 'Server unavailable. Hash not found in local transactions.';
            }
          });
        }
      } catch (_) {
        _animController.stop();
        _animController.reset();
        if (mounted) {
          setState(() {
            _verifying = false;
            _searched = true;
            _errorMessage = 'Verification failed: $e';
          });
        }
      }
    }
  }

  /// Client-side fallback: compute SHA-256 chain from sacco_transactions
  /// and check if the hash matches any block.
  Future<Map<String, dynamic>?> _clientSideVerify(String pastedHash) async {
    try {
      final response = await SupabaseService.client
          .from('sacco_transactions')
          .select('*')
          .order('created_at', ascending: true)
          .limit(200);

      final transactions = List<Map<String, dynamic>>.from(response);
      if (transactions.isEmpty) return null;

      String prevHash = '0000000000000000000000000000000000000000000000000000000000000000';
      final cleaned = pastedHash.toLowerCase().replaceAll(RegExp(r'[^a-f0-9]'), '');

      for (int i = 0; i < transactions.length; i++) {
        final tx = transactions[i];
        final payload = '${tx['transaction_id']}${tx['amount']}${tx['created_at']}$prevHash';
        final currHash = sha256.convert(utf8.encode(payload)).toString();

        // Check if any hash matches
        if (currHash == cleaned || prevHash == cleaned) {
          final txUser = tx['user_id']?.toString() ?? '';
          return {
            'found': true,
            'hash_type': currHash == cleaned ? 'block_hash' : 'prev_hash',
            'block_index': i,
            'transaction_id': tx['transaction_id'],
            'user_id': txUser.isNotEmpty ? txUser : null,
            'amount': tx['amount'],
            'transaction_type': tx['transaction_type'] ?? 'UNKNOWN',
            'status': tx['status'] ?? 'UNKNOWN',
            'prev_hash': prevHash,
            'block_hash': currHash,
            'merkle_root': '',
            'chain_valid': true,
            'created_at': tx['created_at'],
          };
        }

        prevHash = currHash;
      }

      // Also check the genesis prev_hash (all zeros)
      if (cleaned == '0000000000000000000000000000000000000000000000000000000000000000') {
        return {
          'found': true,
          'hash_type': 'prev_hash',
          'block_index': 0,
          'transaction_id': transactions.first['transaction_id'],
          'user_id': null,
          'amount': 0,
          'transaction_type': 'GENESIS',
          'status': 'SYSTEM',
          'prev_hash': '0' * 64,
          'block_hash': '',
          'merkle_root': '',
          'chain_valid': true,
          'created_at': null,
        };
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final found = _result?['found'] == true;
    final chainValid = _result?['chain_valid'] == true;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppConstants.violet.withAlpha(20)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 32, offset: const Offset(0, -8)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag handle ──
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Header with icon ──
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        if (_verifying) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: child,
                          );
                        }
                        return child!;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _verifying
                                ? [AppConstants.cyan.withAlpha(60), AppConstants.violet.withAlpha(60)]
                                : [AppConstants.violet, AppConstants.chainBlue],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.violet.withAlpha(_verifying ? 40 : 20),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _verifying ? Icons.gpp_maybe_rounded : Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify Ledger Hash',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Validate blockchain integrity',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withAlpha(140),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Input section ──
                Container(
                  decoration: BoxDecoration(
                    color: (isDark ? const Color(0xFF050A15) : const Color(0xFFF0F2F5)).withAlpha(160),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _focusNode.hasFocus
                          ? AppConstants.violet.withAlpha(50)
                          : (isDark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(80),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 3,
                        minLines: 1,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: theme.textTheme.bodyLarge?.color,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Paste hash value to verify...\nblock_hash, prev_hash, or merkle_root',
                          hintStyle: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(60),
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      // ── Action row ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: (isDark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(60)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _inputActionBtn(
                              icon: Icons.content_paste_rounded,
                              label: 'Paste',
                              onTap: _pasteFromClipboard,
                            ),
                            const SizedBox(width: 4),
                            if (_controller.text.isNotEmpty)
                              _inputActionBtn(
                                icon: Icons.close_rounded,
                                label: 'Clear',
                                onTap: () {
                                  _controller.clear();
                                  setState(() {
                                    _result = null;
                                    _searched = false;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Verify button ──
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.violet,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      disabledBackgroundColor: AppConstants.violet.withAlpha(80),
                    ),
                    child: _verifying
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withAlpha(200)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Verifying...',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white.withAlpha(200)),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_rounded, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Verify Hash',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                            ],
                          ),
                  ),
                ),

                // ── Results ──
                if (_searched && !_verifying) ...[
                  const SizedBox(height: 20),

                  // Error message
                  if (_errorMessage.isNotEmpty) ...[
                    _buildErrorBanner(theme, _errorMessage),
                    const SizedBox(height: 12),
                  ],

                  // Source indicator
                  if (_verifySource.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            _verifySource == 'server' ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
                            size: 12,
                            color: AppConstants.cyan.withAlpha(150),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _verifySource == 'server' ? 'Verified via blockchain ledger' : 'Verified via local transaction hash',
                            style: TextStyle(fontSize: 10, color: AppConstants.cyan.withAlpha(150), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                  if (!found)
                    _buildNotFound(theme, isDark)
                  else
                    _buildResult(theme, found, chainValid, isDark),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppConstants.violet.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppConstants.violet),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppConstants.violet, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.amber.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConstants.amber.withAlpha(25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.amber.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppConstants.amber, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withAlpha(160), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConstants.coral.withAlpha(6), AppConstants.coral.withAlpha(3)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConstants.coral.withAlpha(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.coral.withAlpha(12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded, color: AppConstants.coral, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            'Hash Not Found',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppConstants.coral, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'This hash does not exist in the blockchain.\nPlease check and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withAlpha(140), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(ThemeData theme, bool found, bool chainValid, bool isDark) {
    final hashType = (_result?['hash_type'] ?? 'unknown').toString();
    final blockIndex = _result?['block_index'];
    final amount = _result?['amount'] ?? 0;
    final txType = (_result?['transaction_type'] ?? 'TX').toString();
    final status = (_result?['status'] ?? 'UNKNOWN').toString();
    final createdAt = _result?['created_at'];

    String matchedHash = '';
    if (hashType == 'block_hash') {
      matchedHash = (_result?['block_hash'] ?? '').toString();
    } else if (hashType == 'prev_hash') {
      matchedHash = (_result?['prev_hash'] ?? '').toString();
    } else {
      matchedHash = (_result?['merkle_root'] ?? '').toString();
    }

    String typeLabel;
    if (hashType == 'block_hash') {
      typeLabel = 'Block Hash';
    } else if (hashType == 'prev_hash') {
      typeLabel = 'Previous Hash';
    } else {
      typeLabel = 'Merkle Root';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            chainValid ? AppConstants.emerald.withAlpha(6) : AppConstants.coral.withAlpha(6),
            chainValid ? AppConstants.emerald.withAlpha(2) : AppConstants.coral.withAlpha(2),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: chainValid ? AppConstants.emerald.withAlpha(25) : AppConstants.coral.withAlpha(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: chainValid ? AppConstants.emerald.withAlpha(10) : AppConstants.coral.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: chainValid ? AppConstants.emerald.withAlpha(15) : AppConstants.coral.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    chainValid ? Icons.verified_rounded : Icons.error_outline_rounded,
                    color: chainValid ? AppConstants.emerald : AppConstants.coral,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chainValid ? 'Hash Verified Successfully' : 'Chain Integrity Compromised',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: chainValid ? AppConstants.emerald : AppConstants.coral,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SHA-256 · $typeLabel',
                        style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withAlpha(140)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Block details ──
          Text(
            'BLOCK DETAILS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _detailRow(theme, 'Block', blockIndex != null ? '#$blockIndex' : '—', isDark),
          _detailRow(theme, 'Type', txType, isDark),
          _detailRow(theme, 'Amount', 'UGX $amount', isDark),
          _detailRow(theme, 'Status', status, isDark),
          if (createdAt != null) _detailRow(theme, 'Time', _formatTime(createdAt), isDark),

          // ── Matched hash ──
          if (matchedHash.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'MATCHED HASH',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: matchedHash.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Hash copied to clipboard'),
                    backgroundColor: AppConstants.emerald,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF050A15) : const Color(0xFFF0F2F5)).withAlpha(160),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  matchedHash.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(ThemeData theme, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF0B1222) : const Color(0xFFF8F9FA)).withAlpha(120),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodyMedium?.color?.withAlpha(140),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.toString();
    }
  }
}

// ─── Individual Block Card ─────────────────────────────────────────────────

class _ChainBlock extends StatelessWidget {
  const _ChainBlock({
    required this.block,
    required this.isLatest,
    required this.isGenesis,
    required this.totalBlocks,
  });

  final Map<String, dynamic> block;
  final bool isLatest;
  final bool isGenesis;
  final int totalBlocks;

  static const List<Color> _hashColors = [
    AppConstants.emerald,
    AppConstants.cyan,
    AppConstants.violet,
    AppConstants.amber,
    AppConstants.chainBlue,
    AppConstants.pink,
    AppConstants.emeraldDark,
    AppConstants.coral,
  ];

  /// Cleans and copies the full hash to clipboard
  void _copyHash(BuildContext context, String rawHash) {
    // Strip whitespace/newlines, lowercase, take first 64 hex chars
    final cleaned = rawHash
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-fA-F0-9]'), '')
        .toLowerCase();
    final display = cleaned.length >= 64 ? cleaned.substring(0, 64) : cleaned;

    Clipboard.setData(ClipboardData(text: display));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text('Hash copied'),
          ],
        ),
        backgroundColor: AppConstants.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final verified = block['status'] == 'SUCCESSFUL';
    final blockIndex = block['block_index'] ?? 0;
    final accentColor = isGenesis
        ? AppConstants.amber
        : (isLatest ? AppConstants.emerald : _hashColors[blockIndex.toInt() % _hashColors.length]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Timeline spine ──
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentColor.withAlpha(40), accentColor.withAlpha(15)],
                      ),
                      border: Border.all(color: accentColor, width: 1.5),
                    ),
                    child: Center(
                      child: isGenesis
                          ? const Icon(Icons.star_rounded, size: 12, color: AppConstants.amber)
                          : Text(
                              '$blockIndex',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: accentColor),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accentColor.withAlpha(40), accentColor.withAlpha(8)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Block content ──
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.cardColor,
                  border: Border.all(
                    color: isLatest
                        ? AppConstants.emerald.withAlpha(40)
                        : (isDark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100),
                    width: isLatest ? 1.5 : 1,
                  ),
                  boxShadow: isLatest
                      ? [BoxShadow(color: AppConstants.emerald.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Row 1: Type badge + block label + status ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              _typeBadge(block['transaction_type'], accentColor),
                              const SizedBox(width: 8),
                              if (isGenesis)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppConstants.amber.withAlpha(15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('GENESIS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppConstants.amber, letterSpacing: 0.5)),
                                ),
                              if (isLatest && !isGenesis)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppConstants.emerald.withAlpha(15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('LATEST', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppConstants.emerald, letterSpacing: 0.5)),
                                ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Block #$blockIndex',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color?.withAlpha(120),
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusDot(verified),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Row 2: Amount ──
                    Text(
                      'UGX ${_formatAmount(block['amount'] ?? 0)}',
                      style: TextStyle(
                        color: AppConstants.emerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      'Nonce: ${block['nonce'] ?? 0}',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Row 3: Hashes with multi-color display + copy ──
                    _hashDisplayBox(context, block, accentColor),

                    const SizedBox(height: 10),

                    // ── Row 4: Timestamp ──
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 10, color: theme.textTheme.bodyMedium?.color?.withAlpha(100)),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(block['created_at']),
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(120),
                          ),
                        ),
                        const Spacer(),
                        if (block['reference_id'] != null)
                          Text(
                            block['reference_id'],
                            style: TextStyle(
                              fontSize: 8,
                              fontFamily: 'monospace',
                              color: theme.textTheme.bodyMedium?.color?.withAlpha(100),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String? type, Color color) {
    final label = type ?? 'TX';
    final icon = label.contains('DEPOSIT')
        ? Icons.arrow_downward_rounded
        : label.contains('WITHDRAW')
            ? Icons.arrow_upward_rounded
            : label.contains('LOAN')
                ? Icons.account_balance_rounded
                : Icons.swap_horiz_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 10, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: verified ? AppConstants.emerald.withAlpha(12) : AppConstants.coral.withAlpha(12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: verified ? AppConstants.emerald : AppConstants.coral,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            verified ? 'Verified' : 'Failed',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: verified ? AppConstants.emerald : AppConstants.coral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hashDisplayBox(BuildContext context, Map<String, dynamic> block, Color accentColor) {
    final theme = Theme.of(context);
    final prevHash = block['prev_hash'] ?? '0' * 64;
    final currHash = block['block_hash'] ?? '0' * 64;
    final merkleRoot = block['merkle_root'] ?? '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (theme.brightness == Brightness.dark ? const Color(0xFF050A15) : const Color(0xFFF0F2F5)).withAlpha(160),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _coloredHashRow(context, 'PREV', prevHash, accentColor.withAlpha(180)),
          const SizedBox(height: 6),
          _coloredHashRow(context, 'HASH', currHash, accentColor),
          if (merkleRoot.isNotEmpty) ...[
            const SizedBox(height: 6),
            _coloredHashRow(context, 'MERKLE', merkleRoot, AppConstants.violet),
          ],
        ],
      ),
    );
  }

  Widget _coloredHashRow(BuildContext context, String label, String hash, Color baseColor) {
    final segments = _splitHash(hash);

    return GestureDetector(
      onTap: () => _copyHash(context, hash),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: baseColor,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                children: List.generate(segments.length, (i) {
                  final segColor = _hashColors[i % _hashColors.length];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: segColor.withAlpha(12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      segments[i],
                      style: TextStyle(
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: segColor,
                        letterSpacing: 0.3,
                        height: 1.3,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy_rounded, size: 10, color: baseColor.withAlpha(100)),
          ],
        ),
      ),
    );
  }

  List<String> _splitHash(String hash) {
    final clean = hash.replaceAll(RegExp(r'[^a-fA-F0-9]'), '0');
    final padded = clean.length >= 64 ? clean.substring(0, 64) : clean.padRight(64, '0');
    final segments = <String>[];
    for (var i = 0; i < padded.length; i += 8) {
      segments.add(padded.substring(i, i + 8));
    }
    return segments;
  }

  String _formatAmount(dynamic value) {
    final num v = (value is num) ? value : 0;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.toString();
    }
  }
}
