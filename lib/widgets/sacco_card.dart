import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';
import 'package:makerere_fintech_app/core/ui/blockchain_card.dart';
import 'package:makerere_fintech_app/models/sacco.dart';

class SaccoCard extends StatelessWidget {
  final Sacco sacco;
  final VoidCallback onTap;

  const SaccoCard({super.key, required this.sacco, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlockchainCard(
      onTap: onTap,
      hasAccentBar: true,
      accentColor: AppConstants.emerald,
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.emerald.withAlpha(25), AppConstants.emerald.withAlpha(10)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.emerald.withAlpha(30), width: 0.5),
            ),
            child: const Icon(Icons.account_balance, color: AppConstants.emerald, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sacco.name,
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sacco.registrationNumber,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(160),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppConstants.emerald.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: AppConstants.emerald,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
