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
  final _descriptionCtrl = TextEditingController();
  String _selectedMethod = 'Mobile Money';
  bool _loading = false;
  String? _selectedSacco;

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
    if (_amountCtrl.text.isEmpty || _selectedSacco == null) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deposit request submitted'), backgroundColor: AppConstants.emerald));
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit Funds')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [theme.scaffoldBackgroundColor, theme.brightness == Brightness.dark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select SACCO', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSacco,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.business)),
                  items: _saccos.map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(value: s['sacco_name'] as String?, child: Text(s['sacco_name'] as String? ?? ''))).toList(),
                  onChanged: (v) => setState(() => _selectedSacco = v),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 20),
                Text('Amount', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 24),
                  decoration: const InputDecoration(prefixText: 'UGX ', prefixStyle: TextStyle(color: AppConstants.emerald, fontSize: 24, fontWeight: FontWeight.w700), hintText: '0.00'),
                ),
                const SizedBox(height: 20),
                Text('Payment Method', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                const SizedBox(height: 12),
                _methodTile('Mobile Money', Icons.phone_android),
                const SizedBox(height: 8),
                _methodTile('Bank Transfer', Icons.account_balance),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Confirm Deposit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodTile(String title, IconData icon) {
    final selected = _selectedMethod == title;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppConstants.emerald.withAlpha(12) : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppConstants.emerald.withAlpha(60) : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppConstants.emerald : theme.textTheme.bodyMedium?.color, size: 22),
            const SizedBox(width: 14),
            Text(title, style: TextStyle(color: selected ? AppConstants.emerald : theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (selected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.check_circle, color: AppConstants.emerald, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
