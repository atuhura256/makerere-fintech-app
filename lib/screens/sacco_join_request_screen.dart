import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

class SaccoJoinRequestScreen extends StatefulWidget {
  final String saccoId;
  final String saccoName;
  final String schemaName;

  const SaccoJoinRequestScreen({
    super.key,
    required this.saccoId,
    required this.saccoName,
    required this.schemaName,
  });

  @override
  State<SaccoJoinRequestScreen> createState() => _SaccoJoinRequestScreenState();
}

class _SaccoJoinRequestScreenState extends State<SaccoJoinRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final user = SupabaseService.currentUser;
    if (user != null) {
      _emailCtrl.text = user.email ?? '';
      _nameCtrl.text = user.userMetadata?['full_name'] ?? '';
      _phoneCtrl.text = user.userMetadata?['phone_number'] ?? '';
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await SupabaseService.submitMembershipRequest(
        saccoId: widget.saccoId,
        schemaName: widget.schemaName,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );

      setState(() {
        _successMessage = 'Your membership enrollment request has been logged successfully! An automated notification was dispatched to the administrators of "${widget.saccoName}" for ledger profile verification.';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission fault: $e'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Membership')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _successMessage != null ? _buildSuccessView() : _buildFormView(theme),
        ),
      ),
    );
  }

  Widget _buildFormView(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join ${widget.saccoName}',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Your application data will be captured securely. Membership actions preserve the system\'s immutable historical records.',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13),
          ),
          const SizedBox(height: 28),

          TextFormField(
            controller: _nameCtrl,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: const InputDecoration(labelText: 'Applicant Full Legal Name', prefixIcon: Icon(Icons.person_outline)),
            validator: (v) => v!.isEmpty ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: const InputDecoration(labelText: 'Contact Mobile Number', prefixIcon: Icon(Icons.phone_android)),
            validator: (v) => v!.isEmpty ? 'Please provide your active phone number' : null,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: const InputDecoration(labelText: 'Active Email Address', prefixIcon: Icon(Icons.mail_outline)),
            validator: (v) => v!.isEmpty ? 'Please enter your email link' : null,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.emerald,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Enrollment Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final theme = Theme.of(context);
    return BlockchainCard(
      hasGlow: true,
      accentColor: AppConstants.emerald,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.forward_to_inbox_rounded, color: AppConstants.emerald, size: 56),
          const SizedBox(height: 16),
          Text('Application Pending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          Text(_successMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.4, color: theme.textTheme.bodyMedium?.color)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to SACCO Portal'),
            ),
          )
        ],
      ),
    );
  }
}
