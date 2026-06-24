import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/services/theme_state.dart';
import 'package:makerere_fintech_app/widgets/glass_bottom_nav_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  theme.scaffoldBackgroundColor,
                  isDark ? const Color(0xFF080E1A) : const Color(0xFFE8F5E9)
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              children: [
                _sectionHeader(theme, 'Appearance'),
                _buildSettingTile(theme, 'Dark Mode', 'Switch between light and dark themes', Switch(
                  value: ThemeState.themeMode.value == ThemeMode.dark,
                  onChanged: (_) => ThemeState.toggleTheme(),
                  activeTrackColor: AppConstants.emerald,
                )),
                const SizedBox(height: 24),
                _sectionHeader(theme, 'Notifications'),
                _buildSettingTile(theme, 'Push Notifications', 'Receive alerts for transactions', Switch(
                  value: true, onChanged: (v) {},
                  activeTrackColor: AppConstants.emerald,
                )),
                _buildSettingTile(theme, 'Email Reports', 'Monthly account ledger logs statements', Switch(
                  value: false, onChanged: (v) {},
                  activeTrackColor: AppConstants.emerald,
                )),
                const SizedBox(height: 24),
                _sectionHeader(theme, 'Security & Encryption'),
                _buildActionTile(theme, 'Hardware Security Keys', Icons.vpn_key_outlined),
                _buildActionTile(theme, 'Biometric Lock Engine', Icons.fingerprint_outlined),
                const SizedBox(height: 24),
                _sectionHeader(theme, 'Legal & Compliance'),
                _buildActionTile(theme, 'Terms of Ledger Service', Icons.description_outlined),
                _buildActionTile(theme, 'UMRA Regulatory Disclosures', Icons.gavel_outlined),
              ],
            ),
          ),
          const Positioned(
            bottom: 20, left: 20, right: 20,
            child: GlassBottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppConstants.emerald,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Container(
            height: 1,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.emerald.withAlpha(80), AppConstants.emerald.withAlpha(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(ThemeData theme, String title, String subtitle, Widget trailing) {
    return BlockchainCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withAlpha(150), fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionTile(ThemeData theme, String title, IconData icon) {
    return BlockchainCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.emerald, size: 20),
          const SizedBox(width: 14),
          Text(title, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15, fontWeight: FontWeight.w500)),
          const Spacer(),
          Icon(Icons.chevron_right, color: theme.textTheme.bodyMedium?.color?.withAlpha(100), size: 18),
        ],
      ),
    );
  }
}
