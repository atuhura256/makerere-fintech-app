import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';

class TenantRegistrationScreen extends StatefulWidget {
  const TenantRegistrationScreen({super.key});

  @override
  State<TenantRegistrationScreen> createState() => _TenantRegistrationScreenState();
}

class _TenantRegistrationScreenState extends State<TenantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _saccoNameCtrl = TextEditingController();
  final _regNumberCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();

  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  Future<void> _registerTenant() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      final currentUser = SupabaseService.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception("Authentication session not found. Please log in first.");
      }

      final String localizedSchema = _saccoNameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

      await SupabaseService.client.from('saccos').insert({
        'sacco_name': _saccoNameCtrl.text.trim(),
        'schema_name': localizedSchema,
        'creator_id': currentUser.id,
        'registration_number': _regNumberCtrl.text.trim(),
        'email_address': _emailCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'bank_name': _bankNameCtrl.text.trim(),
        'bank_account': _bankAccountCtrl.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _successMessage = '✔ "${_saccoNameCtrl.text.trim()}" has been successfully created! Your corporate banking structure is live on the system dashboard ledger.';
      });
    } on Exception catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _saccoNameCtrl.dispose();
    _regNumberCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Register Corporate SACCO')),
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
                if (_successMessage != null) ...[
                  _buildSuccessCard(),
                  const SizedBox(height: 20),
                ],
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppConstants.coral.withAlpha(12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppConstants.coral.withAlpha(30)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppConstants.coral, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppConstants.coral, fontSize: 13)))
                      ],
                    ),
                  ),
                if (_successMessage == null) _buildForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    return BlockchainCard(
      padding: const EdgeInsets.all(20),
      hasGlow: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Corporate SACCO Profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            TextFormField(
              controller: _saccoNameCtrl,
              decoration: const InputDecoration(labelText: 'SACCO Registered Name', prefixIcon: Icon(Icons.business)),
              validator: (v) => v!.isEmpty ? 'SACCO Name cannot be empty' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _regNumberCtrl,
              decoration: const InputDecoration(labelText: 'Regulatory Registration No. (UMRA)', prefixIcon: Icon(Icons.assignment_turned_in)),
              validator: (v) => v!.isEmpty ? 'Registration license number is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Official Corporate Email', prefixIcon: Icon(Icons.email)),
              validator: (v) => v!.isEmpty ? 'Email link is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Primary Support Phone Number', prefixIcon: Icon(Icons.phone)),
              validator: (v) => v!.isEmpty ? 'Phone number required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Headquarters Location / District', prefixIcon: Icon(Icons.location_on)),
              validator: (v) => v!.isEmpty ? 'Location descriptor required' : null,
            ),
            const SizedBox(height: 20),

            const Divider(),
            const SizedBox(height: 12),
            Text('Settlement Bank Escrow Node', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bankNameCtrl,
              decoration: const InputDecoration(labelText: 'Commercial Bank Name (e.g., Stanbic)', prefixIcon: Icon(Icons.account_balance)),
              validator: (v) => v!.isEmpty ? 'Bank name required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bankAccountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Settlement Account Number', prefixIcon: Icon(Icons.badge)),
              validator: (v) => v!.isEmpty ? 'Bank account details required' : null,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerTenant,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Corporate SACCO Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return BlockchainCard(
      hasGlow: true,
      accentColor: AppConstants.emerald,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: AppConstants.emerald, size: 48),
          const SizedBox(height: 12),
          Text('SACCO Live on Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Text(_successMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to Core Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}
