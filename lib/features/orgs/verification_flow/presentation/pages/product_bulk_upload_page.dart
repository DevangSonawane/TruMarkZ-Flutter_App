import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/utils/file_picker_util.dart';
import '../../../../../core/widgets/tmz_card.dart';
import '../../../data/verification_repository.dart';

class ProductBulkUploadPage extends ConsumerStatefulWidget {
  const ProductBulkUploadPage({super.key});

  @override
  ConsumerState<ProductBulkUploadPage> createState() =>
      _ProductBulkUploadPageState();
}

class _ProductBulkUploadPageState extends ConsumerState<ProductBulkUploadPage> {
  bool _didInitFromRoute = false;

  String _sector = 'Consumer Goods & Warranty';
  String _batchName = 'New Product Batch';
  String _templateLabel = 'Classic Card';

  PickedFile? _pickedFile;
  bool _creating = false;
  List<String> _headers = <String>[];

  static const Color _deepBlue = AppColors.deepNavy;

  LinearGradient get _primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.brandBlue, _deepBlue],
  );

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    final Object? extra = GoRouterState.of(context).extra;
    final String? sector = extra is String ? extra : null;
    if (sector != null && sector.trim().isNotEmpty) {
      _sector = sector.trim();
    }

    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    final String? batch = qp['batch'];
    if (batch != null && batch.trim().isNotEmpty) {
      _batchName = batch.trim();
    }
    final String? templateLabel = qp['templateLabel'];
    if (templateLabel != null && templateLabel.trim().isNotEmpty) {
      _templateLabel = templateLabel.trim();
    }
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download template coming soon.')),
    );
  }

  void _openUploadSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Upload Product Data', style: AppTypography.heading1),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Pick an Excel file (.xlsx). For now you can use sample data.',
                  style: AppTypography.body2.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: AppSpacing.x4),
                _SheetAction(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Use Sample File (Demo Mode)',
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _pickedFile = null;
                      _headers = <String>[
                        'product_name',
                        'serial_number',
                        'manufacture_date',
                        'model_number',
                        'warranty_months',
                        'batch_code',
                        'color',
                        'description',
                      ];
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.x2),
                _SheetAction(
                  icon: Icons.folder_open_rounded,
                  label: 'Pick Excel File',
                  onTap: () async {
                    final PickedFile? picked = await FilePickerUtil.pickExcel();
                    if (!mounted) return;
                    if (!context.mounted) return;
                    if (picked == null) return;
                    Navigator.of(context).pop();
                    setState(() {
                      _pickedFile = picked;
                      _headers = <String>[];
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createBatch() async {
    final PickedFile? pickedFile = _pickedFile;
    if (pickedFile == null || _creating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an Excel file first.')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final VerificationRepository repo = ref.read(
        verificationRepositoryProvider,
      );
      final res = await repo.bulkUpload(
        batchName: _batchName,
        description: _sector,
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );
      if (!mounted) return;
      final Uri uri = Uri(
        path: AppRouter.productBatchCreatedPath,
        queryParameters: <String, String>{
          'sector': _sector,
          'batch': _batchName,
          'template': _templateLabel,
          'records': res.totalUploaded.toString(),
          'skipped': res.totalSkipped.toString(),
          'batchId': res.batchId,
        },
      );
      context.push(uri.toString());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => _goBack(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Upload Products'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x4,
                  AppSpacing.x3,
                  AppSpacing.x4,
                  AppSpacing.x4,
                ),
                children: <Widget>[
                  _ProductFlowStepper(
                    stepIndex: 2,
                    gradient: _primaryGradient,
                    labels: const <String>[
                      'Sector',
                      'Product Details',
                      'Upload',
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  TMZCard(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Summary', style: AppTypography.heading2),
                        const SizedBox(height: AppSpacing.x3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            Chip(
                              label: Text(_sector),
                              backgroundColor: AppColors.brandBlue.withAlpha(
                                14,
                              ),
                              labelStyle: AppTypography.caption.copyWith(
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w800,
                              ),
                              side: BorderSide(
                                color: AppColors.brandBlue.withAlpha(24),
                              ),
                            ),
                            _SummaryPill(
                              icon: Icons.folder_rounded,
                              label: _batchName,
                            ),
                            _SummaryPill(
                              icon: Icons.badge_outlined,
                              label: _templateLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  _InfoCard(
                    title: 'Excel Columns',
                    subtitle:
                        'Required: product_name, serial_number, manufacture_date\nOptional: model_number, warranty_months, batch_code, color, description',
                    icon: Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Upload Product Data (.xlsx)',
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  TMZCard(
                    onTap: _openUploadSheet,
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue.withAlpha(14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _pickedFile != null
                                ? Icons.check_circle_rounded
                                : Icons.upload_file_rounded,
                            color: AppColors.brandBlue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _pickedFile != null
                                    ? _pickedFile!.name
                                    : 'Tap to upload your Excel file',
                                style: AppTypography.body1.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _pickedFile != null
                                    ? 'Ready to upload'
                                    : 'We’ll detect rows & validate required columns',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download Excel Template'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandBlue,
                        textStyle: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  if (_pickedFile != null)
                    TMZCard(
                      padding: const EdgeInsets.all(AppSpacing.x4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                'File selected',
                                style: AppTypography.heading2.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.table_chart_rounded,
                                color: AppColors.brandBlue,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x3),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              for (final String h in _headers.take(8))
                                Chip(
                                  label: Text(h),
                                  backgroundColor: AppColors.brandBlue
                                      .withAlpha(12),
                                ),
                            ],
                          ),
                        ],
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
                child: _GradientCtaButton(
                  label: _creating ? 'Creating…' : 'Create Batch',
                  icon: Icons.check_rounded,
                  gradient: _primaryGradient,
                  enabled: _pickedFile != null && !_creating,
                  onPressed: _createBatch,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: onTap == null ? AppColors.border : AppColors.brandBlue,
              width: 1.25,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.brandBlue),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onTap == null)
                Text(
                  'Soon',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.brandBlue),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandBlue.withAlpha(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.brandBlue),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
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

class _ProductFlowStepper extends StatelessWidget {
  const _ProductFlowStepper({
    required this.stepIndex,
    required this.gradient,
    required this.labels,
  });

  final int stepIndex;
  final Gradient gradient;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    const int totalSteps = 3;
    final double progress = stepIndex / (totalSteps - 1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.brandBlue.withAlpha(14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double width = c.maxWidth;
                return Stack(
                  children: <Widget>[
                    Container(
                      width: width,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double t, Widget? child) {
                        return Container(
                          width: width * t,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              for (int i = 0; i < totalSteps; i++) ...<Widget>[
                _MinimalStepDot(
                  active: i == stepIndex,
                  completed: i < stepIndex,
                  gradient: gradient,
                ),
                if (i != totalSteps - 1) const Spacer(),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              for (int i = 0; i < labels.length; i++) ...<Widget>[
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: i == 0
                        ? TextAlign.left
                        : (i == labels.length - 1
                              ? TextAlign.right
                              : TextAlign.center),
                    style: AppTypography.caption.copyWith(
                      color: i == stepIndex
                          ? AppColors.brandBlue
                          : AppColors.textTertiary,
                      fontWeight: i == stepIndex
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MinimalStepDot extends StatelessWidget {
  const _MinimalStepDot({
    required this.active,
    required this.completed,
    required this.gradient,
  });

  final bool active;
  final bool completed;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final double size = active ? 12 : 10;
    final Color fill = completed
        ? AppColors.brandBlue
        : const Color(0xFFEFF3FF);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active || completed ? gradient : null,
        color: active || completed ? null : fill,
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.brandBlue.withAlpha(26),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : const <BoxShadow>[],
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
  final FutureOr<void> Function() onPressed;

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
              onTap: widget.enabled ? () => widget.onPressed() : null,
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
