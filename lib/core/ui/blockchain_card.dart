import 'package:flutter/material.dart';
import 'package:makerere_fintech_app/app/config/app_constants.dart';

class BlockchainCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? accentColor;
  final bool hasAccentBar;
  final bool hasGlow;
  final VoidCallback? onTap;
  final double elevation;

  const BlockchainCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.accentColor,
    this.hasAccentBar = false,
    this.hasGlow = false,
    this.onTap,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = accentColor ?? AppConstants.emerald;

    final card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1A2332).withAlpha(120)
              : const Color(0xFFD0D5DD).withAlpha(120),
        ),
        boxShadow: [
          if (hasGlow)
            BoxShadow(
              color: accent.withAlpha(isDark ? 15 : 10),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasAccentBar
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent,
                          accent.withAlpha(80),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            )
          : child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class BlockchainMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const BlockchainMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlockchainCard(
      hasGlow: true,
      accentColor: color,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Fixes: Column takes only what it needs
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withAlpha(30), width: 0.5),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Container(
                width: 4, height: 4,
                decoration: BoxDecoration(color: color.withAlpha(60), shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 14 to save space
          if (isLoading)
            SizedBox(
              width: 20, height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppConstants.emerald),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          const SizedBox(height: 4),
          // Fixes: Wrapped label in Flexible to prevent bottom overflow
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(140),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BlockchainSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? accentColor;

  const BlockchainSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? AppConstants.emerald;

    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          height: 1.5,
          width: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withAlpha(100),
                accent.withAlpha(0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BlockchainNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final String route;

  const BlockchainNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
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
          color: active
              ? AppConstants.emerald.withAlpha(20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: active
              ? Border.all(
                  color: AppConstants.emerald.withAlpha(40),
                  width: 0.5,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: active
                      ? AppConstants.emerald
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withAlpha(120),
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
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? AppConstants.emerald
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withAlpha(120),
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlockchainBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const BlockchainBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(30), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class BlockchainActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const BlockchainActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, route);
      },
      child: BlockchainCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withAlpha(30),
                  width: 0.5,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withAlpha(10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlockchainStatusChip extends StatelessWidget {
  final String status;

  const BlockchainStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color = (status == 'APPROVED' ||
            status == 'DISBURSED' ||
            status == 'SUCCESSFUL')
        ? AppConstants.emerald
        : status == 'PENDING'
            ? AppConstants.amber
            : AppConstants.coral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(30), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
