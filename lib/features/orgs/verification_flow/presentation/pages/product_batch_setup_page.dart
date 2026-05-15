import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_card.dart';
import '../../../../../core/widgets/tmz_input.dart';

enum _ProductTemplate { classicCard, circularBadge, reportSheet }

enum _BlockchainVisibility { publicRegistry, privateRegistry }

class ProductBatchSetupPage extends StatefulWidget {
  const ProductBatchSetupPage({super.key});

  @override
  State<ProductBatchSetupPage> createState() => _ProductBatchSetupPageState();
}

class _ProductBatchSetupPageState extends State<ProductBatchSetupPage> {
  bool _didInitFromRoute = false;
  String _sector = 'Consumer Goods & Warranty';
  String _mode = 'verification'; // 'verification' | 'warranty'

  late final TextEditingController _batchNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _unitsController;

  _ProductTemplate _selectedTemplate = _ProductTemplate.classicCard;
  _BlockchainVisibility _visibility = _BlockchainVisibility.publicRegistry;

  static const Color _deepBlue = AppColors.deepNavy;

  LinearGradient get _primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.brandBlue, _deepBlue],
  );

  @override
  void initState() {
    super.initState();
    _batchNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _unitsController = TextEditingController(text: '100');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromRoute) return;
    _didInitFromRoute = true;

    final String mode =
        (GoRouterState.of(context).uri.queryParameters['mode'] ??
                'verification')
            .trim()
            .toLowerCase();
    if (mode == 'warranty' || mode == 'verification') {
      _mode = mode;
    }

    final Object? extra = GoRouterState.of(context).extra;
    final String? sector = extra is String ? extra : null;
    if (sector != null && sector.trim().isNotEmpty) {
      _sector = sector.trim();
    }
  }

  @override
  void dispose() {
    _batchNameController.dispose();
    _descriptionController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.dashboardPath);
    }
  }

  int _units() => int.tryParse(_unitsController.text.trim()) ?? 0;

  bool get _canContinue =>
      _batchNameController.text.trim().isNotEmpty && _units() > 0;

  String _templateLabel(_ProductTemplate template) => switch (template) {
    _ProductTemplate.classicCard => 'Classic Card',
    _ProductTemplate.circularBadge => 'Circular Badge',
    _ProductTemplate.reportSheet => 'Report Sheet',
  };

  String _templateId(_ProductTemplate template) => switch (template) {
    _ProductTemplate.classicCard => 'classic_card',
    _ProductTemplate.circularBadge => 'circular_badge',
    _ProductTemplate.reportSheet => 'report_sheet',
  };

  void _continue(BuildContext context) {
    if (!_canContinue) return;

    final Map<String, String> qp = <String, String>{
      'batch': _batchNameController.text.trim(),
      'template': _templateId(_selectedTemplate),
      'templateLabel': _templateLabel(_selectedTemplate),
      'units': _units().toString(),
      'visibility': _visibility.name,
      'mode': _mode,
      if (_descriptionController.text.trim().isNotEmpty)
        'desc': _descriptionController.text.trim(),
    };

    final Uri uri = Uri(
      path: AppRouter.productBulkUploadPath,
      queryParameters: qp,
    );
    context.push(uri.toString(), extra: _sector);
  }

  @override
  Widget build(BuildContext context) {
    final String modeLabel = _mode == 'warranty' ? 'Warranty' : 'Verification';
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
        title: const Text('Product Details'),
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
                    stepIndex: 1,
                    gradient: _primaryGradient,
                    labels: const <String>[
                      'Sector',
                      'Product Details',
                      'Upload',
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  Text('Batch Metadata', style: AppTypography.display2),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    'Add batch details and select the certificate format.',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  TMZInput(
                    label: 'Batch Name',
                    hint: _mode == 'warranty'
                        ? 'e.g. Warranty Cards — May 2026'
                        : 'e.g. Verification Certificates — May 2026',
                    controller: _batchNameController,
                    onChanged: (_) => setState(() {}),
                    prefixIcon: Icons.folder_rounded,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  _MultilineInput(
                    label: 'Description (Optional)',
                    hint: 'Short description (max 3 lines)',
                    controller: _descriptionController,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZCard(
                    padding: const EdgeInsets.all(AppSpacing.x4),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.category_rounded,
                          color: AppColors.brandBlue,
                        ),
                        const SizedBox(width: AppSpacing.x3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Product Category',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  label: Text('$_sector • $modeLabel'),
                                  backgroundColor: AppColors.brandBlue
                                      .withAlpha(14),
                                  labelStyle: AppTypography.body2.copyWith(
                                    color: AppColors.brandBlue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  side: BorderSide(
                                    color: AppColors.brandBlue.withAlpha(24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Certificate Template',
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  SizedBox(
                    height: 192,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        _TemplateCard(
                          title: 'Classic Card',
                          icon: Icons.badge_outlined,
                          selected:
                              _selectedTemplate == _ProductTemplate.classicCard,
                          onTap: () => setState(
                            () => _selectedTemplate =
                                _ProductTemplate.classicCard,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x3),
                        _TemplateCard(
                          title: 'Circular Badge',
                          icon: Icons.account_circle_outlined,
                          selected:
                              _selectedTemplate ==
                              _ProductTemplate.circularBadge,
                          onTap: () => setState(
                            () => _selectedTemplate =
                                _ProductTemplate.circularBadge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x3),
                        _TemplateCard(
                          title: 'Report Sheet',
                          icon: Icons.description_outlined,
                          selected:
                              _selectedTemplate == _ProductTemplate.reportSheet,
                          onTap: () => setState(
                            () => _selectedTemplate =
                                _ProductTemplate.reportSheet,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  TMZInput(
                    label: 'Number of Units',
                    hint: 'e.g. 500',
                    controller: _unitsController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.format_list_numbered_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    'Blockchain Visibility',
                    style: AppTypography.heading2.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ChoiceChipCard(
                          title: 'Public Registry',
                          subtitle: 'Searchable by anyone',
                          icon: Icons.public_rounded,
                          selected:
                              _visibility ==
                              _BlockchainVisibility.publicRegistry,
                          onTap: () => setState(
                            () => _visibility =
                                _BlockchainVisibility.publicRegistry,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x3),
                      Expanded(
                        child: _ChoiceChipCard(
                          title: 'Private',
                          subtitle: 'Share by link only',
                          icon: Icons.lock_rounded,
                          selected:
                              _visibility ==
                              _BlockchainVisibility.privateRegistry,
                          onTap: () => setState(
                            () => _visibility =
                                _BlockchainVisibility.privateRegistry,
                          ),
                        ),
                      ),
                    ],
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
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  gradient: _primaryGradient,
                  enabled: _canContinue,
                  onPressed: () => _continue(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderSide borderSide = selected
        ? const BorderSide(color: AppColors.brandBlue, width: 2)
        : BorderSide(color: AppColors.border.withAlpha(120));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.fromBorderSide(borderSide),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.brandBlue.withAlpha(14),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brandBlue.withAlpha(18)
                          : const Color(0xFFEFF3FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: AppColors.brandBlue, size: 34),
                  ),
                  const SizedBox(height: AppSpacing.x3),
                  Text(
                    title,
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.brandBlue
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[AppColors.brandBlue, Color(0xFF004AC6)],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChipCard extends StatelessWidget {
  const _ChoiceChipCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.brandBlue : AppColors.border,
              width: selected ? 2 : 1.25,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brandBlue.withAlpha(16)
                      : const Color(0xFFEFF3FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.brandBlue),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.body2.copyWith(
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? AppColors.brandBlue
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.brandBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MultilineInput extends StatefulWidget {
  const _MultilineInput({
    required this.label,
    this.hint,
    required this.controller,
    required this.maxLines,
    required this.onChanged,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  State<_MultilineInput> createState() => _MultilineInputState();
}

class _MultilineInputState extends State<_MultilineInput> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _focused ? AppColors.brandBlue : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.25),
          ),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            style: AppTypography.body2.copyWith(
              color: AppColors.textPrimary,
              height: 1.25,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.body2.copyWith(
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
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
