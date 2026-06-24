import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

class SecurityKeyManagementScreen extends StatefulWidget {
  const SecurityKeyManagementScreen({super.key});

  @override
  State<SecurityKeyManagementScreen> createState() => _SecurityKeyManagementScreenState();
}

class _SecurityKeyManagementScreenState extends State<SecurityKeyManagementScreen> {
  bool _showKey = false;

  String get _maskedSessionId {
    final session = SupabaseService.currentSession;
    if (session == null) return 'Not authenticated';
    final id = session.accessToken;
    if (id.length <= 12) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = SupabaseService.currentUser;
    final session = SupabaseService.currentSession;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Keys', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
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
                _buildSecurityHeader(context),
                const SizedBox(height: 24),
                if (user != null && session != null) ...[
                  _buildKeyCard(context, 'Session Token', _showKey ? session.accessToken : _maskedSessionId, Icons.vpn_key_rounded, AppConstants.emerald),
                  const SizedBox(height: 16),
                  _buildKeyCard(context, 'User ID', user.id, Icons.fingerprint, AppConstants.cyan),
                  const SizedBox(height: 16),
                  _buildKeyCard(context, 'Email', user.email ?? 'N/A', Icons.email_outlined, AppConstants.violet),
                  const SizedBox(height: 24),
                  _buildSecurityTips(context),
                ] else ...[
                  _buildNotSignedIn(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityHeader(BuildContext context) {
    final theme = Theme.of(context);
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
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AppConstants.emerald.withAlpha(40), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.security_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Management',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'View your cryptographic credentials and session keys',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyCard(BuildContext context, String title, String value, IconData icon, Color accentColor) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.cardColor,
        border: Border.all(
          color: (theme.brightness == Brightness.dark ? const Color(0xFF1A2332) : const Color(0xFFD0D5DD)).withAlpha(100),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 15 : 5), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              if (title == 'Session Token')
                GestureDetector(
                  onTap: () => setState(() => _showKey = !_showKey),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 16, color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (theme.brightness == Brightness.dark ? const Color(0xFF050A15) : const Color(0xFFF0F2F5)).withAlpha(180),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: accentColor,
                      letterSpacing: 0.5,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title copied to clipboard'),
                        backgroundColor: AppConstants.emerald,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.copy_rounded, size: 16, color: accentColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTips(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.amber.withAlpha(8),
            AppConstants.amber.withAlpha(3),
          ],
        ),
        border: Border.all(color: AppConstants.amber.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline, size: 16, color: AppConstants.amber),
              ),
              const SizedBox(width: 10),
              Text(
                'Security Best Practices',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _tipRow(theme, 'Never share your session token with anyone'),
          const SizedBox(height: 8),
          _tipRow(theme, 'Always sign out from shared devices'),
          const SizedBox(height: 8),
          _tipRow(theme, 'Use a strong, unique password for your account'),
        ],
      ),
    );
  }

  Widget _tipRow(ThemeData theme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 5, height: 5,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppConstants.amber),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildNotSignedIn(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppConstants.emerald.withAlpha(10),
            ),
            child: const Icon(Icons.lock_outline, size: 40, color: AppConstants.emerald),
          ),
          const SizedBox(height: 16),
          Text('Sign in to view your security keys', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }
}
