import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class RegistrySearchPage extends StatelessWidget {
  const RegistrySearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 18,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('TruMarkZ'),
          ],
        ),
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
          Text('Registry Search', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, credential ID...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.brandBlue,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: <Widget>[
              _FilterChip(label: 'All', selected: true),
              const _FilterChip(label: 'Individuals', selected: false),
              const _FilterChip(label: 'Organisations', selected: false),
              const _FilterChip(label: 'F', selected: false),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: <Widget>[
              Text(
                '3 RESULTS FOUND',
                style: AppTypography.caption.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
              const Spacer(),
              Text(
                'Relevance',
                style: AppTypography.caption.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Icon(Icons.swap_vert_rounded, size: 18, color: scheme.primary),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          _ResultCard(
            title: 'Julian Sterling',
            subtitle: 'Senior Safety Engineer',
            meta: 'Affiliation\nGlobal Safety Compliance Corp.',
            onTap: () => context.go(AppRouter.publicVerificationResultPath),
          ),
          const SizedBox(height: AppSpacing.x2),
          _ResultCard(
            title: 'Apex Industrial Ltd.',
            subtitle: 'Certified Logistics Partner',
            meta: 'HQ Location\nSingapore, Financial District',
            onTap: () => context.go(AppRouter.publicVerificationResultPath),
          ),
          const SizedBox(height: AppSpacing.x2),
          _ResultCard(
            title: 'ISO-9001 Seal Manufacturing Standard',
            subtitle: 'Issued by Bureau Veritas Certification',
            meta: 'Issuing Authority\nBureau Veritas Certification',
            onTap: () => context.go(AppRouter.publicVerificationResultPath),
          ),
          const SizedBox(height: AppSpacing.x6),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Viewing public records'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? scheme.primary.withAlpha(28) : scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: selected ? scheme.primary : scheme.onSurface.withAlpha(160),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: scheme.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.badge_outlined, color: scheme.primary),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(title, style: AppTypography.heading2),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.body2.copyWith(
                            color: scheme.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.green.withAlpha(60)),
                    ),
                    child: Text(
                      'VERIFIED',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      meta,
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                  Text(
                    'View',
                    style: AppTypography.body2.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: scheme.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
