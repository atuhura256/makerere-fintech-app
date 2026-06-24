import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';

class GlassBottomNavBar extends StatelessWidget {
  const GlassBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: (isDark
                ? const Color(0xFF0B1222)
                : Colors.white)
                .withAlpha(220),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1A2332).withAlpha(100)
                  : const Color(0xFFD0D5DD).withAlpha(100),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D68F).withAlpha(isDark ? 8 : 4),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 30 : 10),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(context, Icons.home_rounded, 'Home', currentRoute == '/', '/'),
              _navItem(context, Icons.account_balance_rounded, 'SACCOs', currentRoute == '/saccos', '/saccos'),
              _navItem(context, Icons.swap_horiz_rounded, 'Transact', currentRoute == '/transactions', '/transactions'),
              _navItem(context, Icons.verified_rounded, 'Audit', currentRoute == '/realtime-ledger', '/realtime-ledger'),
              _navItem(context, Icons.person_rounded, 'Profile', currentRoute == '/profile', '/profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, String route) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () {
        if (route != ModalRoute.of(context)?.settings.name) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppConstants.emerald.withAlpha(18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: active
              ? Border.all(color: AppConstants.emerald.withAlpha(35), width: 0.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: active ? AppConstants.emerald : textColor.withAlpha(160),
                  size: 22,
                ),
                if (active)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppConstants.emerald,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00D68F),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? AppConstants.emerald : textColor.withAlpha(160),
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: active ? 0.2 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
