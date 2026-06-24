import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/screens/tenant_registration_screen.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await SupabaseService.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');
    } on Exception catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showIndividualRegistrationSheet(BuildContext context) {
    final theme = Theme.of(context);
    final emailRegisterCtrl = TextEditingController();
    final passwordRegisterCtrl = TextEditingController();
    final nameRegisterCtrl = TextEditingController();
    bool isRegistering = false;
    String? modalNotification;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Member Profile', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Join as an individual saver to access SACCO networks.', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
              const SizedBox(height: 20),

              if (modalNotification != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppConstants.emerald.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppConstants.emerald.withAlpha(40)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mark_email_unread_rounded, color: AppConstants.emerald, size: 44),
                      const SizedBox(height: 12),
                      Text(
                        modalNotification!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('I Understand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]
              else ...[
                TextField(
                  controller: nameRegisterCtrl,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailRegisterCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordRegisterCtrl,
                  obscureText: true,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isRegistering ? null : () async {
                      if (emailRegisterCtrl.text.isEmpty || passwordRegisterCtrl.text.isEmpty) return;
                      setModalState(() => isRegistering = true);
                      try {
                        await SupabaseService.signUp(
                          email: emailRegisterCtrl.text.trim(),
                          password: passwordRegisterCtrl.text,
                          userMetadata: {'full_name': nameRegisterCtrl.text.trim(), 'role': 'member'},
                          appMetadata: {'sacco_name': 'Individual Member Pool', 'payout_medium': 'Mobile Money', 'payout_account': '0700000000'},
                        );

                        setModalState(() {
                          isRegistering = false;
                          modalNotification = 'An activation link has been delivered to your email: ${emailRegisterCtrl.text.trim()}.\n\nPlease check your inbox and verify your profile before signing in.';
                        });
                      } catch (e) {
                        setModalState(() => isRegistering = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent)
                        );
                      }
                    },
                    child: isRegistering
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign Up as Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.dark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(context),
                  const SizedBox(height: 48),
                  _buildLoginCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppConstants.emerald.withAlpha(50),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.account_balance_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          'Makerere Fintech',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFFEEF2F6)
                : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Secure Multi-SACCO Platform',
          style: TextStyle(
            fontSize: 14,
            color: theme.brightness == Brightness.dark
                ? Colors.grey[500]
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final theme = Theme.of(context);
    return BlockchainCard(
      padding: const EdgeInsets.all(24),
      radius: 20,
      hasGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign In', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Use your Supabase credentials', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
          const SizedBox(height: 24),
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
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppConstants.coral, fontSize: 13))),
                ],
              ),
            ),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("New to the platform? ", style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 13)),
                  GestureDetector(
                    onTap: () => _showIndividualRegistrationSheet(context),
                    child: const Text('Create Account', style: TextStyle(color: AppConstants.emerald, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
