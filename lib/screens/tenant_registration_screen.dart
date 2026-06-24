import 'package:flutter/material.dart';
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
        'creator_email': currentUser.email,
        'registration_number': _regNumberCtrl.text.trim(),
        'email_address': _emailCtrl.text.trim(),
        'phone_number': _phoneCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'bank_name': _bankNameCtrl.text.trim(),
        'bank_account': _bankAccountCtrl.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      await SupabaseService.client.from('sacco_admins').insert({
        'schema_name': localizedSchema,
        'admin_email': currentUser.email,
        'admin_id_ref': currentUser.id,
        'role': 'CREATOR',
      });

      setState(() {
        _successMessage = '"${_saccoNameCtrl.text.trim()}" has been successfully created! Your corporate banking structure is live on the system dashboard ledger.';
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register SACCO', style: TextStyle(fontWeight: FontWeight.w700)),
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
                if (_successMessage != null) ...[
                  _buildSuccessCard(theme),
                  const SizedBox(height: 20),
                ],
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppConstants.coral.withAlpha(12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppConstants.coral.withAlpha(30)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppConstants.coral, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppConstants.coral, fontSize: 13))),
                      ],
                    ),
                  ),
                if (_successMessage == null) _buildForm(context, theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 24),
        _buildSectionLabel(theme, 'SACCO Information'),
        const SizedBox(height: 12),
        _buildInput(theme, 'SACCO Registered Name', Icons.business, _saccoNameCtrl, 'e.g., Kampala Savings SACCO'),
        const SizedBox(height: 14),
        _buildInput(theme, 'Regulatory Registration No.', Icons.assignment_turned_in, _regNumberCtrl, 'e.g., UMRA/2024/00123'),
        const SizedBox(height: 14),
        _buildInput(theme, 'Official Corporate Email', Icons.email, _emailCtrl, 'info@sacco.org'),
        const SizedBox(height: 14),
        _buildInput(theme, 'Primary Phone Number', Icons.phone, _phoneCtrl, 'e.g., 0700123456'),
        const SizedBox(height: 14),
        _buildInput(theme, 'Headquarters Location', Icons.location_on, _locationCtrl, 'e.g., Kampala, Uganda'),
        const SizedBox(height: 28),
        _buildSectionLabel(theme, 'Settlement Bank Details'),
        const SizedBox(height: 12),
        _buildInput(theme, 'Bank Name', Icons.account_balance, _bankNameCtrl, 'e.g., Stanbic Bank Uganda'),
        const SizedBox(height: 14),
        _buildInput(theme, 'Account Number', Icons.badge, _bankAccountCtrl, 'e.g., 9030001234567'),
        const SizedBox(height: 32),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            (theme.brightness == Brightness.dark ? const Color(0xFF0B1222) : const Color(0xFFF0FFF4)),
          ],
        ),
        border: Border.all(color: AppConstants.emerald.withAlpha(25)),
        boxShadow: [
          BoxShadow(color: AppConstants.emerald.withAlpha(8), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppConstants.emerald.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New SACCO Registration',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Register a new multi-tenant financial federation node',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(
            color: AppConstants.emerald,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInput(ThemeData theme, String label, IconData icon, TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 10 : 4), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 13),
          prefixIcon: Icon(icon, color: AppConstants.emerald, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(80), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (v) => v!.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerTenant,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.emerald,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: AppConstants.emerald.withAlpha(60),
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_business_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Register SACCO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            (theme.brightness == Brightness.dark ? const Color(0xFF0B1222) : const Color(0xFFF0FFF4)),
          ],
        ),
        border: Border.all(color: AppConstants.emerald.withAlpha(25)),
        boxShadow: [
          BoxShadow(color: AppConstants.emerald.withAlpha(12), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.emerald.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppConstants.emerald, size: 56),
          ),
          const SizedBox(height: 20),
          Text(
            'SACCO Registered Successfully',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _successMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: theme.textTheme.bodyMedium?.color?.withAlpha(180)),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Return to Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.emerald,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
