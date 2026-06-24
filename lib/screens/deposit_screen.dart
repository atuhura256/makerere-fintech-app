import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _amountCtrl = TextEditingController();
  String _selectedMethod = 'Mobile Money';
  bool _loading = false;
  String? _selectedSacco;

  List<Map<String, dynamic>> _saccos = [];
  final _amountFocusNode = FocusNode();

  final List<double> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _loadSaccos();
  }

  Future<void> _loadSaccos() async {
    try { _saccos = await SupabaseService.getAllSaccos(); if (mounted) setState(() {}); } catch (_) {}
  }

  Future<void> _submit() async {
    if (_amountCtrl.text.isEmpty || _selectedSacco == null) return;
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
      final sacco = _saccos.firstWhere((s) => s['sacco_id'] == _selectedSacco);

      await SupabaseService.recordLedgerTransaction(
        schemaName: sacco['schema_name'] ?? '',
        payload: {
          'sacco_id': sacco['sacco_id'],
          'user_id': user.id,
          'account_type': 'SAVINGS',
          'transaction_type': 'DEPOSIT',
          'amount': amount,
          'reference_id': 'DEP-${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deposit recorded successfully'),
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
          SnackBar(content: Text('Deposit failed: $e'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Funds', style: TextStyle(fontWeight: FontWeight.w700)),
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
                _buildSectionLabel(context, 'Select SACCO'),
                const SizedBox(height: 8),
                _buildSaccoSelector(context),
                const SizedBox(height: 24),
                _buildSectionLabel(context, 'Enter Amount'),
                const SizedBox(height: 8),
                _buildAmountInput(context),
                const SizedBox(height: 16),
                _buildQuickAmounts(context),
                const SizedBox(height: 24),
                _buildSectionLabel(context, 'Payment Method'),
                const SizedBox(height: 12),
                _buildMethodSelector(context),
                const SizedBox(height: 24),
                _buildSummaryCard(context),
                const SizedBox(height: 24),
                _buildSubmitButton(context),
              ],
            ),
          ),
        ),
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

  Widget _buildSaccoSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: (isDark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 15 : 5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSacco,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.business_outlined, size: 18, color: theme.textTheme.bodyMedium?.color?.withAlpha(140)),
              const SizedBox(width: 12),
              Text('Choose a SACCO network', style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(140))),
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
                        style: const TextStyle(
                          color: AppConstants.emerald,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedSacco = v),
        ),
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
          color: _amountFocusNode.hasFocus
              ? AppConstants.emerald.withAlpha(80)
              : (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
        ),
        boxShadow: _amountFocusNode.hasFocus
            ? [BoxShadow(color: AppConstants.emerald.withAlpha(10), blurRadius: 16, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _amountCtrl,
        focusNode: _amountFocusNode,
        keyboardType: TextInputType.number,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixText: 'UGX ',
          prefixStyle: TextStyle(
            color: AppConstants.emerald,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
          hintText: '0.00',
          hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withAlpha(80),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmounts(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickAmounts.map((amount) {
        final isActive = _amountCtrl.text == amount.toStringAsFixed(0);
        return GestureDetector(
          onTap: () {
            setState(() => _amountCtrl.text = amount.toStringAsFixed(0));
            _amountCtrl.selection = TextSelection.fromPosition(
              TextPosition(offset: _amountCtrl.text.length),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppConstants.emerald : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppConstants.emerald
                    : (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A2332)
                        : const Color(0xFFD0D5DD)).withAlpha(120),
              ),
            ),
            child: Text(
              'UGX ${_formatAmount(amount)}',
              style: TextStyle(
                color: isActive ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMethodSelector(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _methodTile(context, 'Mobile Money', Icons.phone_android, 'Pay via MTN / Airtel Mobile Money'),
        const SizedBox(height: 10),
        _methodTile(context, 'Bank Transfer', Icons.account_balance, 'Direct bank transfer to SACCO account'),
      ],
    );
  }

  Widget _methodTile(BuildContext context, String title, IconData icon, String subtitle) {
    final selected = _selectedMethod == title;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppConstants.emerald.withAlpha(10) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppConstants.emerald.withAlpha(60) : theme.dividerColor.withAlpha(120),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppConstants.emerald.withAlpha(15), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? AppConstants.emerald.withAlpha(20) : theme.dividerColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? AppConstants.emerald : theme.textTheme.bodyMedium?.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? AppConstants.emerald : theme.textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(140),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle, color: AppConstants.emerald, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final fee = amount * 0.005;
    final total = amount + fee;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            (theme.brightness == Brightness.dark ? const Color(0xFF0B1222) : const Color(0xFFF8FFF8)),
          ],
        ),
        border: Border.all(
          color: AppConstants.emerald.withAlpha(30),
        ),
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
                child: const Icon(Icons.receipt_long_outlined, size: 16, color: AppConstants.emerald),
              ),
              const SizedBox(width: 10),
              Text(
                'Transaction Summary',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow(theme, 'Amount', 'UGX ${_formatAmount(amount)}', null),
          const SizedBox(height: 8),
          _summaryRow(theme, 'Processing Fee (0.5%)', 'UGX ${_formatAmount(fee)}', AppConstants.amber),
          const SizedBox(height: 8),
          Container(height: 1, color: theme.dividerColor.withAlpha(80)),
          const SizedBox(height: 8),
          _summaryRow(theme, 'Total Debit', 'UGX ${_formatAmount(total)}', AppConstants.emerald),
        ],
      ),
    );
  }

  Widget _summaryRow(ThemeData theme, String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
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
          shadowColor: AppConstants.emerald.withAlpha(60),
        ),
        child: _loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wallet_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Confirm Deposit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}
