import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/services/supabase_service.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr.isNotEmpty ? dateStr : 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = SupabaseService.currentUser;
    final email = user?.email ?? 'Not signed in';
    final name = user?.userMetadata?['full_name'] as String? ?? email.split('@').first;
    final phone = user?.userMetadata?['phone_number'] as String? ?? 'Not set';
    final createdAt = user != null ? _formatDate(user.createdAt) : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details', style: TextStyle(fontWeight: FontWeight.w700)),
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
              children: [
                _buildProfileBanner(context, name, email),
                const SizedBox(height: 24),
                _buildInfoCard(context, 'Personal Information', [
                  _infoRow(theme, 'Full Name', name, Icons.person_outline),
                  _infoRow(theme, 'Email Address', email, Icons.email_outlined),
                  _infoRow(theme, 'Phone Number', phone, Icons.phone_android),
                  _infoRow(theme, 'Member Since', createdAt, Icons.calendar_today),
                ]),
                const SizedBox(height: 16),
                _buildInfoCard(context, 'Account Security', [
                  _infoRow(theme, 'User ID', user?.id ?? 'N/A', Icons.fingerprint),
                  _infoRow(theme, 'Email Verified', user?.emailConfirmedAt != null ? 'Verified (${_formatDate(user!.emailConfirmedAt!)})' : 'Pending', Icons.verified_user),
                ]),
                const SizedBox(height: 24),
                _buildEditButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBanner(BuildContext context, String name, String email) {
    final theme = Theme.of(context);
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
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppConstants.emerald, AppConstants.emeraldDark]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AppConstants.emerald.withAlpha(40), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name.substring(0, 2).toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(email, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(160), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> rows) {
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.emerald.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, size: 16, color: AppConstants.emerald),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.dividerColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppConstants.emerald.withAlpha(180)),
          ),
          const SizedBox(width: 14),
          // Wrapped the Column in Flexible to prevent overflow
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1, // Ensures long text stays on one line
                  overflow: TextOverflow.ellipsis, // Adds '...' if the text is too long
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.emerald,
          side: const BorderSide(color: AppConstants.emerald, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
