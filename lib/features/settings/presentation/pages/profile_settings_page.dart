import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_card.dart';
import '../../../../main.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeMode currentMode = context.themeController.themeMode;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isLightSelected = currentMode == ThemeMode.light;
    final bool isDarkSelected = currentMode == ThemeMode.dark;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go(AppRouter.notificationsPath),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          TMZCard(
            child: ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: scheme.primary.withAlpha(28),
                child: const Icon(Icons.person_rounded, color: AppColors.brandBlue),
              ),
              title: Text('Alex Thompson', style: AppTypography.heading2),
              subtitle: Row(
                children: <Widget>[
                  Text(
                    'alex.t@trumarkz.io',
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.primary.withAlpha(80)),
                    ),
                    child: Text(
                      'Verified Org',
                      style: AppTypography.caption.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('ACCOUNT', style: AppTypography.label),
          const SizedBox(height: AppSpacing.x2),
          TMZCard(
            child: ListTile(
              leading: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.brandBlue),
              title: const Text('Notifications'),
              subtitle: const Text('Verification updates and alerts'),
              onTap: () => context.go(AppRouter.notificationsPath),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          TMZCard(
            child: ListTile(
              leading:
                  const Icon(Icons.shield_outlined, color: AppColors.brandBlue),
              title: const Text('2FA Authentication'),
              subtitle: const Text('Enabled'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('APPEARANCE', style: AppTypography.label),
          const SizedBox(height: AppSpacing.x2),
          TMZCard(
            child: ListTile(
              leading: const Icon(Icons.palette_rounded, color: AppColors.brandBlue),
              title: const Text('Theme'),
              trailing: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _ModeChip(
                      label: 'Light',
                      selected: isLightSelected,
                      onTap: () => context.themeController.setThemeMode(ThemeMode.light),
                    ),
                    const SizedBox(width: 6),
                    _ModeChip(
                      label: 'Dark',
                      selected: isDarkSelected,
                      onTap: () => context.themeController.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('CREDENTIALS', style: AppTypography.label),
          const SizedBox(height: AppSpacing.x2),
          TMZCard(
            child: ListTile(
              leading: const Icon(Icons.shield_rounded, color: AppColors.brandBlue),
              title: const Text('Identity Wallet'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(AppRouter.walletPath),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          const TMZCard(
            child: ListTile(
              leading: Icon(Icons.picture_as_pdf_outlined, color: AppColors.brandBlue),
              title: Text('PDF Export History'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text('RESOURCES', style: AppTypography.label),
          const SizedBox(height: AppSpacing.x2),
          Row(
            children: <Widget>[
              Expanded(
                child: TMZCard(
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.support_agent_rounded),
                      const SizedBox(height: 8),
                      Text('Support', style: AppTypography.body2),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: TMZCard(
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.info_outline_rounded),
                      const SizedBox(height: 8),
                      Text('About', style: AppTypography.body2),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            'TruMarkZ v2.4.1 (Stable)',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: scheme.onSurface.withAlpha(140),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? scheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: selected ? Border.all(color: scheme.outlineVariant) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: selected ? scheme.primary : scheme.onSurface.withAlpha(150),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.onSurface : scheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
