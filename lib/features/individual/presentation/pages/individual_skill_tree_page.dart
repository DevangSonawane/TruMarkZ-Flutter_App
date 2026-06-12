import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/file_picker_util.dart';
import '../../../orgs/verification_flow/presentation/pages/flow_step_progress.dart';

class IndividualSkillTreePage extends StatefulWidget {
  const IndividualSkillTreePage({super.key});

  @override
  State<IndividualSkillTreePage> createState() =>
      _IndividualSkillTreePageState();
}

class _IndividualSkillTreePageState extends State<IndividualSkillTreePage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  final ScrollController _scrollController = ScrollController();

  final List<_SkillStepDraft> _steps = <_SkillStepDraft>[
    _SkillStepDraft(
      title: 'Technical Skills',
      subtitle:
          'Add tools, frameworks, systems, and platform knowledge you want to highlight.',
      hint:
          'Mention languages, software, tools, APIs, frameworks, or certifications.',
    ),
    _SkillStepDraft(
      title: 'Soft Skills',
      subtitle:
          'Capture the communication and collaboration strengths that support your work.',
      hint:
          'Describe leadership, teamwork, adaptability, problem solving, or time management.',
    ),
    _SkillStepDraft(
      title: 'Education and Experience',
      subtitle:
          'Add academic history, internships, work experience, and learning milestones.',
      hint:
          'Include degrees, institutions, companies, roles, dates, or notable outcomes.',
    ),
    _SkillStepDraft(
      title: 'Projects and Achievements',
      subtitle:
          'Showcase the work, wins, and proof points that make your profile stand out.',
      hint:
          'Share portfolios, awards, hackathons, launches, results, or personal projects.',
    ),
  ];

  int _activeStep = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    for (final _SkillStepDraft step in _steps) {
      for (final _SkillEntryDraft entry in step.entries) {
        entry.dispose();
      }
    }
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (_activeStep > 0) {
      setState(() => _activeStep -= 1);
      return;
    }
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.individualIdentityPath);
    }
  }

  void _goNext() {
    if (_activeStep < _steps.length - 1) {
      setState(() => _activeStep += 1);
      _scrollToTop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skill tree draft is ready for backend wiring.'),
      ),
    );
  }

  void _addFieldGroup([int insertAfterIndex = -1]) {
    setState(() {
      final List<_SkillEntryDraft> entries = _steps[_activeStep].entries;
      final int insertIndex = insertAfterIndex < 0
          ? entries.length
          : (insertAfterIndex + 1).clamp(0, entries.length);
      entries.insert(insertIndex, _SkillEntryDraft());
    });
    _scrollToBottom();
  }

  Future<void> _pickDocument(int entryIndex) async {
    final _SkillEntryDraft entry = _steps[_activeStep].entries[entryIndex];
    final PickedFile? picked = await FilePickerUtil.pickDocument();
    if (!mounted || picked == null) return;
    setState(() {
      entry.documentName = picked.name;
      entry.documentExtension = picked.extension;
    });
  }

  void _removeEntry(int index) {
    if (_steps[_activeStep].entries.length == 1) {
      _steps[_activeStep].entries[index].clear();
      setState(() {});
      return;
    }

    final _SkillEntryDraft removed = _steps[_activeStep].entries.removeAt(
      index,
    );
    removed.dispose();
    setState(() {});
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 320,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  InputDecoration _fieldDecoration({
    required String hint,
    int? minLines,
    int? maxLines,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.brandBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      isDense: true,
      alignLabelWithHint: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final _SkillStepDraft step = _steps[_activeStep];
    final int stepNumber = _activeStep + 1;
    final int totalSteps = _steps.length;
    final double progress = stepNumber / totalSteps;

    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = constraints.maxWidth < _referenceWidth
                ? constraints.maxWidth
                : _referenceWidth;
            final double scale = contentWidth / _referenceWidth;
            double s(double v) => v * scale;

            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(s(16), s(8), s(16), 0),
                      child: Row(
                        children: <Widget>[
                          InkResponse(
                            onTap: () => _goBack(context),
                            radius: s(22),
                            child: SvgPicture.asset(
                              'assets/icons/figma/new_batch_back.svg',
                              width: s(24),
                              height: s(24),
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          SizedBox(width: s(12)),
                          Expanded(
                            child: Text(
                              'Skills',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: s(21),
                                fontWeight: FontWeight.w600,
                                height: 19.5 / 21,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(24)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _panelBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(20)),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(32),
                                  s(16),
                                  s(24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    FlowStepProgress(
                                      scale: scale,
                                      stepLabel:
                                          'STEP $stepNumber OF $totalSteps',
                                      progressLabel:
                                          '${(progress * 100).round()}%',
                                      fillFactor: progress,
                                    ),
                                    SizedBox(height: s(24)),
                                    Text(
                                      step.title,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(24),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: s(1.18),
                                        height: 22.6 / 24,
                                        color: const Color(0xFF323232),
                                      ),
                                    ),
                                    SizedBox(height: s(12)),
                                    Text(
                                      step.subtitle,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: s(1.18),
                                        height: 17.75 / 12,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                    SizedBox(height: s(20)),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      child: Column(
                                        key: ValueKey<String>(
                                          '${_activeStep}_${step.entries.length}',
                                        ),
                                        children: <Widget>[
                                          for (int i = 0;
                                              i < step.entries.length;
                                              i++) ...<Widget>[
                                            _SkillEntryCard(
                                              scale: scale,
                                              index: i,
                                              title:
                                                  step.entries.length == 1
                                                      ? step.title
                                                      : '${step.title} ${i + 1}',
                                              entry: step.entries[i],
                                              onRemove: () =>
                                                  _removeEntry(i),
                                              onPickDocument: () =>
                                                  _pickDocument(i),
                                              onAddBelow: () =>
                                                  _addFieldGroup(i),
                                              fieldDecoration: _fieldDecoration,
                                            ),
                                            if (i != step.entries.length - 1)
                                              SizedBox(height: s(16)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _BottomNav(
                              scale: scale,
                              child: _BottomContinue(
                                scale: scale,
                                label:
                                    _activeStep == totalSteps - 1
                                        ? 'Finish'
                                        : 'Continue',
                                onTap: _goNext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SkillStepDraft {
  _SkillStepDraft({
    required this.title,
    required this.subtitle,
    required this.hint,
  }) : entries = <_SkillEntryDraft>[_SkillEntryDraft()];

  final String title;
  final String subtitle;
  final String hint;
  final List<_SkillEntryDraft> entries;
}

class _SkillEntryDraft {
  _SkillEntryDraft()
      : skillName = TextEditingController(),
        about = TextEditingController();

  final TextEditingController skillName;
  final TextEditingController about;
  String? documentName;
  String? documentExtension;

  void clear() {
    skillName.clear();
    about.clear();
    documentName = null;
    documentExtension = null;
  }

  void dispose() {
    skillName.dispose();
    about.dispose();
  }
}

class _SkillEntryCard extends StatelessWidget {
  const _SkillEntryCard({
    required this.scale,
    required this.index,
    required this.title,
    required this.entry,
    required this.onRemove,
    required this.onPickDocument,
    required this.onAddBelow,
    required this.fieldDecoration,
  });

  final double scale;
  final int index;
  final String title;
  final _SkillEntryDraft entry;
  final VoidCallback onRemove;
  final VoidCallback onPickDocument;
  final VoidCallback onAddBelow;
  final InputDecoration Function({
    required String hint,
    int? minLines,
    int? maxLines,
  }) fieldDecoration;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final bool hasDocument = (entry.documentName ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(s(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: s(38),
                height: s(38),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(s(12)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(13),
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
              SizedBox(width: s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: s(2)),
                    Text(
                      'Fill the details below and attach supporting documents if you have them.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(11),
                        fontWeight: FontWeight.w500,
                        height: 16 / 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: s(8)),
              InkResponse(
                onTap: onRemove,
                radius: s(18),
                child: Container(
                  width: s(32),
                  height: s(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(s(10)),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s(14)),
          Text(
            'Skill name',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(11),
              fontWeight: FontWeight.w700,
              letterSpacing: s(0.7),
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: s(8)),
          TextField(
            controller: entry.skillName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(14),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
            decoration: fieldDecoration(
              hint: 'e.g. Flutter, Negotiation, B.Com, Hackathon',
            ),
          ),
          SizedBox(height: s(14)),
          Text(
            'More about the skill',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(11),
              fontWeight: FontWeight.w700,
              letterSpacing: s(0.7),
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: s(8)),
          TextField(
            controller: entry.about,
            minLines: 4,
            maxLines: 6,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(14),
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F172A),
            ),
            decoration: fieldDecoration(
              hint:
                  'Write a short summary, impact, tools used, years of experience, or context.',
            ),
          ),
          SizedBox(height: s(14)),
          Text(
            'Upload your documents',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(11),
              fontWeight: FontWeight.w700,
              letterSpacing: s(0.7),
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: s(8)),
          InkWell(
            onTap: onPickDocument,
            borderRadius: BorderRadius.circular(s(16)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(s(14)),
              decoration: BoxDecoration(
                color: hasDocument
                    ? const Color(0xFFF0F7FF)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(s(16)),
                border: Border.all(
                  color: hasDocument
                      ? AppColors.brandBlue.withValues(alpha: 0.20)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: s(40),
                    height: s(40),
                    decoration: BoxDecoration(
                      color: hasDocument
                          ? AppColors.brandBlue.withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(s(12)),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      hasDocument
                          ? Icons.description_rounded
                          : Icons.cloud_upload_outlined,
                      color: hasDocument
                          ? AppColors.brandBlue
                          : const Color(0xFF64748B),
                      size: s(20),
                    ),
                  ),
                  SizedBox(width: s(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          hasDocument ? entry.documentName! : 'Tap to upload',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(13),
                            fontWeight: FontWeight.w700,
                            height: 19 / 13,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: s(2)),
                        Text(
                          hasDocument
                              ? 'Replace the uploaded document'
                              : 'PDF, PNG, JPG, or WEBP',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(11),
                            fontWeight: FontWeight.w500,
                            height: 16 / 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: s(8)),
                  if (hasDocument)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: s(10),
                        vertical: s(5),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(s(999)),
                        border: Border.all(
                          color: AppColors.brandBlue.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        (entry.documentExtension ?? '').isNotEmpty
                            ? entry.documentExtension!.toUpperCase()
                            : 'FILE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(10),
                          fontWeight: FontWeight.w700,
                          letterSpacing: s(0.6),
                          color: AppColors.brandBlue,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      size: s(22),
                      color: const Color(0xFFCBD5E1),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: s(14)),
          SizedBox(
            width: double.infinity,
            height: s(48),
            child: OutlinedButton.icon(
              onPressed: onAddBelow,
              icon: Icon(
                Icons.add_rounded,
                size: s(18),
                color: AppColors.brandBlue,
              ),
              label: Text(
                'Add Skills',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(14),
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandBlue,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.brandBlue.withValues(alpha: 0.20),
                  width: 1.25,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(s(16)),
                ),
                backgroundColor: const Color(0xFFF8FBFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.scale,
    required this.child,
  });

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: s(12.864), sigmaY: s(12.864)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            s(13.604),
            s(12.864),
            s(13.668),
            s(12.864),
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(204),
            border: Border(
              top: BorderSide(color: const Color(0xFFF3F4F6), width: s(1.072)),
            ),
          ),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );
  }
}

class _BottomContinue extends StatelessWidget {
  const _BottomContinue({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return SizedBox(
      height: s(60),
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandBlue,
          borderRadius: BorderRadius.circular(s(16)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(s(16)),
            onTap: onTap,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: s(18),
                      fontWeight: FontWeight.w700,
                      height: 28 / 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: s(10)),
                  SvgPicture.asset(
                    'assets/icons/figma/new_batch_continue_arrow.svg',
                    width: s(16),
                    height: s(16),
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
