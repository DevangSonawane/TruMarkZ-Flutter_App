import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class CredentialsGeneratedPage extends StatelessWidget {
  const CredentialsGeneratedPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final int? parsed = int.tryParse(value);
    return parsed ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;
    final String batchName =
        (qp['batch'] ?? 'Driver Verification Q1').trim().isNotEmpty
        ? qp['batch']!.trim()
        : 'Driver Verification Q1';
    final int createdCount = _tryParseInt(
      qp['created'],
      fallback: _tryParseInt(qp['records'], fallback: 80),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 22,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('Success'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.x4),
                children: <Widget>[
                  const SizedBox(height: AppSpacing.x4),
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(18),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        size: 56,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Credentials generated',
                    textAlign: TextAlign.center,
                    style: AppTypography.display2,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Batch created successfully. You can now track progress.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: scheme.onSurface.withAlpha(160),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  TMZCard(
                    child: ListTile(
                      leading: const Icon(Icons.analytics_outlined),
                      title: const Text('Batch Report'),
                      subtitle: Text(
                        '$batchName\nCreated $createdCount credentials',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x2,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TMZButton(
                      label: 'View Batch Report',
                      icon: Icons.chevron_right_rounded,
                      onPressed: () {
                        final String qs = qp.entries
                            .map(
                              (MapEntry<String, String> e) =>
                                  '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
                            )
                            .join('&');
                        context.go(
                          qs.isEmpty
                              ? AppRouter.appBatchTrackingDetailPath
                              : '${AppRouter.appBatchTrackingDetailPath}?$qs',
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    TMZButton(
                      label: 'Back to Batches',
                      variant: TMZButtonVariant.secondary,
                      icon: Icons.bar_chart_rounded,
                      onPressed: () => context.go(AppRouter.appBatchesPath),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
