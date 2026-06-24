import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _recipientCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _fromSacco, _toSacco;
  bool _loading = false;
  List<Map<String, dynamic>> _saccos = [];

  @override
  void initState() {
    super.initState();
    _loadSaccos();
  }

  Future<void> _loadSaccos() async {
    try { _saccos = await SupabaseService.getAllSaccos(); if (mounted) setState(() {}); } catch (_) {}
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _fromSacco == null || _toSacco == null) return;
    setState(() => _loading = true);

    final user = SupabaseService.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first'), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount'), backgroundColor: Colors.orangeAccent, behavior: SnackBarBehavior.floating),
        );
      }
      return;
    }

    try {
      final fromSacco = _saccos.firstWhere((s) => s['sacco_id'] == _fromSacco);

      final refId = 'TRF-${DateTime.now().millisecondsSinceEpoch}';

      await SupabaseService.recordLedgerTransaction(
        schemaName: fromSacco['schema_name'] ?? '',
        payload: {
          'sacco_id': fromSacco['sacco_id'],
          'user_id': user.id,
          'account_type': 'SAVINGS',
          'transaction_type': 'TRANSFER_OUT',
          'amount': amount,
          'reference_id': refId,
        },
      );

      if (_toSacco != null) {
        try {
          final toSacco = _saccos.firstWhere((s) => s['sacco_id'] == _toSacco);
          await SupabaseService.recordLedgerTransaction(
            schemaName: toSacco['schema_name'] ?? '',
            payload: {
              'sacco_id': toSacco['sacco_id'],
              'user_id': user.id,
              'account_type': 'SAVINGS',
              'transaction_type': 'TRANSFER_IN',
              'amount': amount,
              'reference_id': refId,
            },
          );
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transfer initiated successfully'),
            backgroundColor: AppConstants.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transfer failed: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Funds', style: TextStyle(fontWeight: FontWeight.w700)),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTransferHeader(context),
                const SizedBox(height: 24),
                _buildSectionLabel(context, 'From SACCO'),
                const SizedBox(height: 8),
                _buildSaccoDropdown(context, _fromSacco, Icons.arrow_upward, (v) => setState(() => _fromSacco = v)),
                const SizedBox(height: 20),
                _buildSectionLabel(context, 'To SACCO'),
                const SizedBox(height: 8),
                _buildSaccoDropdown(context, _toSacco, Icons.arrow_downward, (v) => setState(() => _toSacco = v)),
                const SizedBox(height: 24),
                _buildSectionLabel(context, 'Recipient'),
                const SizedBox(height: 8),
                _buildRecipientInput(context),
                const SizedBox(height: 24),
                _buildSectionLabel(context, 'Amount'),
                const SizedBox(height: 8),
                _buildAmountInput(context),
                const SizedBox(height: 32),
                _buildSubmitButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransferHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
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
          color: AppConstants.emerald.withAlpha(25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.emerald.withAlpha(8),
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
            child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cross-SACCO Transfer',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transfer funds between SACCO networks',
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
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSaccoDropdown(BuildContext context, String? currentValue, IconData icon, ValueChanged<String?> onChanged) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 15 : 5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, size: 18, color: theme.textTheme.bodyMedium?.color?.withAlpha(140)),
              const SizedBox(width: 12),
              Text('Select SACCO', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(140))),
            ],
          ),
          dropdownColor: theme.cardColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppConstants.emerald),
          items: _saccos.map<DropdownMenuItem<String>>((s) {
            final name = s['sacco_name'] as String? ?? '';
            return DropdownMenuItem<String>(
              value: name,
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AppConstants.emerald.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'SC',
                        style: const TextStyle(color: AppConstants.emerald, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildRecipientInput(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 15 : 5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.person_outline, size: 20, color: theme.textTheme.bodyMedium?.color?.withAlpha(140)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _recipientCtrl,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter recipient name or phone',
                hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(100)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 15 : 5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _amountCtrl,
        keyboardType: TextInputType.number,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixText: 'UGX ',
          prefixStyle: const TextStyle(color: AppConstants.emerald, fontSize: 28, fontWeight: FontWeight.w800),
          hintText: '0.00',
          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(80), fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.emerald,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Send Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }
}
