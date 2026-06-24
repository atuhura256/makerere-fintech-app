import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

class SaccoLoanApplicationScreen extends StatefulWidget {
  final String saccoId;
  final String saccoName;
  final String schemaName;

  const SaccoLoanApplicationScreen({
    super.key,
    required this.saccoId,
    required this.saccoName,
    required this.schemaName,
  });

  @override
  State<SaccoLoanApplicationScreen> createState() => _SaccoLoanApplicationScreenState();
}

class _SaccoLoanApplicationScreenState extends State<SaccoLoanApplicationScreen> {
  final _amountCtrl = TextEditingController();
  int _selectedDuration = 3;
  double _baseInterestRate = 5.5;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(_updateLiveCalculatedInterest);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateLiveCalculatedInterest() async {
    final principal = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (principal <= 10000) return;

    try {
      final response = await SupabaseService.client.rpc('calculate_dynamic_loan_interest', params: {
        'p_principal': principal,
        'p_months': _selectedDuration,
      });

      if (mounted && response != null) {
        setState(() {
          _baseInterestRate = (response as num).toDouble();
        });
      }
    } catch (_) {
      setState(() {
        _baseInterestRate = 5.0 + (_selectedDuration / 3) * 0.5;
      });
    }
  }

  double get _calculatedMonthlyPayment {
    final principal = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (principal <= 0) return 0;
    final totalWithInterest = principal * (1 + ((_baseInterestRate / 100) * (_selectedDuration / 12)));
    return totalWithInterest / _selectedDuration;
  }

  double get _totalRepayment {
    final principal = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (principal <= 0) return 0;
    return principal * (1 + ((_baseInterestRate / 100) * (_selectedDuration / 12)));
  }

  Future<void> _submitLoanForm() async {
    final principal = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (principal <= 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid amount greater than UGX 10,000'),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception("Authorization session context missing.");

      await SupabaseService.client.from('sacco_loan_requests').insert({
        'sacco_id': widget.saccoId.isNotEmpty ? widget.saccoId : null,
        'schema_name': widget.schemaName.trim().toLowerCase(),
        'user_id': user.id,
        'applicant_name': user.userMetadata?['full_name'] ?? user.email ?? 'SACCO Member',
        'principal_amount': principal,
        'duration_months': _selectedDuration,
        'calculated_interest_rate': _baseInterestRate,
        'status': 'PENDING',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Credit application submitted successfully'),
            backgroundColor: AppConstants.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Credit submission fault: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final principal = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.darkBg : AppConstants.lightBg,
      appBar: AppBar(
        title: const Text('Apply for Credit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSaccoInfo(context),
            const SizedBox(height: 28),
            _buildSectionLabel(context, 'Loan Principal (UGX)'),
            const SizedBox(height: 8),
            _buildAmountInput(context),
            const SizedBox(height: 24),
            _buildSectionLabel(context, 'Repayment Period'),
            const SizedBox(height: 8),
            _buildDurationSelector(context),
            const SizedBox(height: 28),
            _buildLoanBreakdown(context, principal),
            const SizedBox(height: 32),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSaccoInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
          color: AppConstants.emerald.withAlpha(25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.emerald, AppConstants.emeraldDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_score_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Credit Application',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.saccoName,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppConstants.emerald.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.emerald.withAlpha(30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppConstants.emerald)),
                const SizedBox(width: 5),
                const Text('ACTIVE', style: TextStyle(color: AppConstants.emerald, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
      ),
      child: TextField(
        controller: _amountCtrl,
        keyboardType: TextInputType.number,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 24, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixText: 'UGX ',
          prefixStyle: const TextStyle(color: AppConstants.emerald, fontSize: 24, fontWeight: FontWeight.w700),
          hintText: 'e.g., 500000',
          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(80)),
        ),
      ),
    );
  }

  Widget _buildDurationSelector(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(120),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedDuration,
          isExpanded: true,
          dropdownColor: theme.cardColor,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppConstants.emerald),
          items: const [
            DropdownMenuItem(value: 3, child: Text('3 Months - Short Term')),
            DropdownMenuItem(value: 6, child: Text('6 Months - Medium Term')),
            DropdownMenuItem(value: 12, child: Text('12 Months - Long Term')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedDuration = val);
              _updateLiveCalculatedInterest();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLoanBreakdown(BuildContext context, double principal) {
    final theme = Theme.of(context);
    final hasPrincipal = principal > 0;

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
          color: AppConstants.emerald.withAlpha(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConstants.emerald.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
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
                child: const Icon(Icons.calculate_outlined, size: 16, color: AppConstants.emerald),
              ),
              const SizedBox(width: 10),
              Text(
                'Loan Breakdown',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _breakdownRow(theme, 'Principal Amount', 'UGX ${_formatAmount(principal)}', null),
          const SizedBox(height: 10),
          _breakdownRow(theme, 'Interest Rate (APR)', '$_baseInterestRate%', AppConstants.emerald),
          const SizedBox(height: 10),
          _breakdownRow(theme, 'Duration', '$_selectedDuration months', AppConstants.cyan),
          if (hasPrincipal) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: theme.dividerColor.withAlpha(80)),
            const SizedBox(height: 10),
            _breakdownRow(theme, 'Monthly Installment', 'UGX ${_formatAmount(_calculatedMonthlyPayment)}', AppConstants.amber),
            const SizedBox(height: 10),
            _breakdownRow(theme, 'Total Repayment', 'UGX ${_formatAmount(_totalRepayment)}', AppConstants.emerald),
          ],
          if (!hasPrincipal)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.amber.withAlpha(10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppConstants.amber.withAlpha(25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppConstants.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enter an amount above to see repayment breakdown',
                        style: TextStyle(color: AppConstants.amber, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _breakdownRow(ThemeData theme, String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(180), fontSize: 12),
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
        onPressed: _isProcessing ? null : _submitLoanForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.emerald,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isProcessing
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Submit Credit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
