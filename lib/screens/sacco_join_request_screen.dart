import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
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
        _successMessage = 'Your membership request has been submitted successfully! The administrators of "${widget.saccoName}" will review your application.';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission fault: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Membership', style: TextStyle(fontWeight: FontWeight.w700)),
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
            child: _successMessage != null ? _buildSuccessView(theme) : _buildFormView(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 28),
          _buildSectionLabel(theme, 'Personal Details'),
          const SizedBox(height: 12),
          _buildInput(theme, 'Full Legal Name', Icons.person_outline, _nameCtrl, 'Enter your full name'),
          const SizedBox(height: 14),
          _buildInput(theme, 'Mobile Number', Icons.phone_android, _phoneCtrl, 'e.g., 0700123456'),
          const SizedBox(height: 14),
          _buildInput(theme, 'Email Address', Icons.email_outlined, _emailCtrl, 'your@email.com'),
          const SizedBox(height: 32),
          _buildSubmitButton(theme),
        ],
      ),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppConstants.emerald.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Join ${widget.saccoName}',
            style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete the form below to request membership. Your information will be reviewed by the SACCO administrators.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Text(
      label,
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInput(ThemeData theme, String label, IconData icon, TextEditingController ctrl, String hint) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.cardColor,
        border: Border.all(
          color: (isDark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(isDark ? 10 : 4), blurRadius: 8, offset: const Offset(0, 2)),
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
          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(80), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (v) => v!.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
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
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
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
              BoxShadow(color: AppConstants.emerald.withAlpha(10), blurRadius: 24, offset: const Offset(0, 8)),
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
                child: const Icon(Icons.forward_to_inbox_rounded, color: AppConstants.emerald, size: 56),
              ),
              const SizedBox(height: 20),
              Text(
                'Application Submitted',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color, letterSpacing: -0.5),
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
                  label: const Text('Return to SACCO'),
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
        ),
      ],
    );
  }
}
