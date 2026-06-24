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
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfer initiated'), backgroundColor: AppConstants.emerald));
      Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Funds')),
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
                Text('From SACCO', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _fromSacco,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.arrow_upward)),
                  items: _saccos.map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(value: s['sacco_name'] as String?, child: Text(s['sacco_name'] as String? ?? ''))).toList(),
                  onChanged: (v) => setState(() => _fromSacco = v),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 20),
                Text('To SACCO', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _toSacco,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.arrow_downward)),
                  items: _saccos.map<DropdownMenuItem<String>>((s) => DropdownMenuItem<String>(value: s['sacco_name'] as String?, child: Text(s['sacco_name'] as String? ?? ''))).toList(),
                  onChanged: (v) => setState(() => _toSacco = v),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 20),
                Text('Recipient', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(controller: _recipientCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.person), hintText: 'Enter name or phone')),
                const SizedBox(height: 20),
                Text('Amount', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(controller: _amountCtrl, keyboardType: TextInputType.number, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 24), decoration: const InputDecoration(prefixText: 'UGX ', prefixStyle: TextStyle(color: AppConstants.emerald, fontSize: 24, fontWeight: FontWeight.w700), hintText: '0.00')),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Transfer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
