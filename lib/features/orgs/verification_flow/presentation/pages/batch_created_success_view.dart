import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';

class BatchCreatedSuccessView extends StatelessWidget {
  const BatchCreatedSuccessView({
    super.key,
    required this.heroAssetPath,
    required this.title,
    required this.subtitle,
    required this.batchName,
    required this.batchIdLabel,
    required this.batchIdValue,
    required this.metrics,
    required this.primaryActionLabel,
    required this.primaryAction,
    required this.secondaryActionLabel,
    required this.secondaryAction,
    this.banners = const <BatchCreatedBanner>[],
    this.heroSize = 148,
  });

  final String heroAssetPath;
  final String title;
  final String subtitle;
  final String batchName;
  final String batchIdLabel;
  final String batchIdValue;
  final List<BatchCreatedMetric> metrics;
  final String primaryActionLabel;
  final VoidCallback primaryAction;
  final String secondaryActionLabel;
  final VoidCallback secondaryAction;
  final List<BatchCreatedBanner> banners;
  final double heroSize;

  static String _shortId(String id) {
    final String v = id.trim();
    if (v.isEmpty) return '—';
    return v.length <= 12 ? v : '${v.substring(0, 12)}…';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  36,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: heroSize,
                      height: heroSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEEF3FF),
                          width: 4,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.brandBlue.withAlpha(16),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        heroAssetPath,
                        width: heroSize * 0.82,
                        height: heroSize * 0.82,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.display2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x6),
                  TMZCard(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Batch Details',
                                style: AppTypography.heading2.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.folder_rounded,
                              color: AppColors.brandBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Text(
                          batchName,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          batchIdLabel.toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _shortId(batchIdValue),
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Row(
                          children: <Widget>[
                            for (int i = 0; i < metrics.length; i++) ...<Widget>[
                              Expanded(
                                child: _MetricTile(metric: metrics[i]),
                              ),
                              if (i != metrics.length - 1)
                                const SizedBox(width: AppSpacing.x3),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (banners.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.x4),
                    for (int i = 0; i < banners.length; i++) ...<Widget>[
                      _InfoBanner(banner: banners[i]),
                      if (i != banners.length - 1)
                        const SizedBox(height: AppSpacing.x3),
                    ],
                  ],
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
                    _GradientCtaButton(
                      label: primaryActionLabel,
                      icon: Icons.arrow_forward_rounded,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[AppColors.brandBlue, AppColors.deepNavy],
                      ),
                      enabled: true,
                      onPressed: primaryAction,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    TMZButton(
                      label: secondaryActionLabel,
                      icon: Icons.dashboard_rounded,
                      variant: TMZButtonVariant.secondary,
                      onPressed: secondaryAction,
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

class BatchCreatedMetric {
  const BatchCreatedMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class BatchCreatedBanner {
  const BatchCreatedBanner({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bg,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final Color bg;
  final IconData icon;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final BatchCreatedMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            metric.label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.value,
            style: AppTypography.heading1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.banner});

  final BatchCreatedBanner banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: banner.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: banner.color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(banner.icon, color: banner.color),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  banner.title,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner.subtitle,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCtaButton extends StatefulWidget {
  const _GradientCtaButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_GradientCtaButton> createState() => _GradientCtaButtonState();
}

class _GradientCtaButtonState extends State<_GradientCtaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          widget.label,
          style: AppTypography.button.copyWith(color: Colors.white),
        ),
        const SizedBox(width: 10),
        Icon(widget.icon, color: Colors.white, size: 18),
      ],
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: widget.enabled ? 1 : 0.45,
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(40),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: widget.enabled ? widget.onPressed : null,
              onHighlightChanged: (bool value) =>
                  setState(() => _isPressed = value),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 90),
                scale: _isPressed ? 0.985 : 1,
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
