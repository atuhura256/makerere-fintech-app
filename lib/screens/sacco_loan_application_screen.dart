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

  Future<void> _submitLoanForm() async {
    final principal = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (principal <= 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than UGX 10,000'), backgroundColor: Colors.orangeAccent)
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
          const SnackBar(content: Text('✔ Credit application submitted successfully to the credit desk!'), backgroundColor: AppConstants.emerald)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Credit submission fault: $e'), backgroundColor: Colors.redAccent)
        );
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
        title: const Text('Apply for Credit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SACCO Node Network', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(widget.saccoName, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            Text('Principal Amount Needed (UGX)', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: const InputDecoration(
                labelText: 'Loan Principal',
                prefixIcon: Icon(Icons.account_balance_outlined, color: AppConstants.emerald),
                hintText: 'e.g., 500000',
              ),
            ),
            const SizedBox(height: 24),

            Text('Repayment Matrix Window', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedDuration,
                  isExpanded: true,
                  dropdownColor: theme.cardColor,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('3 Months Amortization Pool')),
                    DropdownMenuItem(value: 6, child: Text('6 Months Amortization Pool')),
                    DropdownMenuItem(value: 12, child: Text('12 Months Amortization Pool')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDuration = val);
                      _updateLiveCalculatedInterest();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            BlockchainCard(
              padding: const EdgeInsets.all(20),
              hasGlow: true,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Assigned Interest Rate', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                      Row(
                        children: [
                          Text('$_baseInterestRate%', style: const TextStyle(color: AppConstants.emerald, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 4),
                          Text('Fixed APR', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Monthly Installment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        'UGX ${_calculatedMonthlyPayment.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppConstants.emerald, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _submitLoanForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.emerald,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Credit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
