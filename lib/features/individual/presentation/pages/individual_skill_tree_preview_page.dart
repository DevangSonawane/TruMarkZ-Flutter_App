import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../../core/models/auth_models.dart';
import '../../../../../core/models/skill_tree_models.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/skill_tree_repository.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import 'individual_skill_tree_overview_page.dart';

class IndividualSkillTreePreviewPage extends ConsumerStatefulWidget {
  const IndividualSkillTreePreviewPage({super.key});

  @override
  ConsumerState<IndividualSkillTreePreviewPage> createState() =>
      _IndividualSkillTreePreviewPageState();
}

class _IndividualSkillTreePreviewPageState
    extends ConsumerState<IndividualSkillTreePreviewPage> {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _industry = TextEditingController();
  final TextEditingController _address = TextEditingController();

  bool _didSeedFromProfile = false;
  Timer? _existingSkillsLoaderTimer;
  bool _showOverviewAfterLoader = false;

  @override
  void dispose() {
    _existingSkillsLoaderTimer?.cancel();
    _fullName.dispose();
    _email.dispose();
    _mobile.dispose();
    _industry.dispose();
    _address.dispose();
    super.dispose();
  }

  void _seedFromProfile(UserProfile? profile) {
    if (_didSeedFromProfile) return;
    if (profile == null) return;

    _fullName.text = profile.fullName?.trim() ?? '';
    _email.text = profile.email.trim();
    _mobile.text = profile.mobile?.trim() ?? '';
    _industry.text = profile.industry?.trim() ?? '';
    _address.text = profile.address?.trim() ?? '';
    _didSeedFromProfile = true;
  }

  InputDecoration _decoration({
    required String hint,
    Widget? prefixIcon,
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
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 52),
      isDense: true,
    );
  }

  void _startSkillTree() {
    if (_formKey.currentState?.validate() != true) return;
    context.push(AppRouter.individualSkillTreeBuildPath);
  }

  Widget _loaderScaffold() {
    return Scaffold(
      backgroundColor: AppColors.brandBlue,
      body: Center(
        child: LoadingAnimationWidget.dotsTriangle(
          color: Colors.white,
          size: 42,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final UserProfile? profile = authAsync.value?.userProfile;
    final AsyncValue<SkillsMeResponse> skillsAsync = ref.watch(
      mySkillsProvider,
    );
    _seedFromProfile(profile);

    if (skillsAsync.isLoading && !skillsAsync.hasValue) {
      return _loaderScaffold();
    }

    if (skillsAsync.hasValue && skillsAsync.value!.total > 0) {
      if (!_showOverviewAfterLoader) {
        _existingSkillsLoaderTimer ??= Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            _showOverviewAfterLoader = true;
          });
        });
      }
      return Scaffold(
        backgroundColor: AppColors.brandBlue,
        body: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.brandBlue),
              ),
            ),
            Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: Colors.white,
                size: 42,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_showOverviewAfterLoader,
                child: AnimatedOpacity(
                  opacity: _showOverviewAfterLoader ? 1 : 0,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOut,
                  child: const IndividualSkillTreeOverviewPage(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    _existingSkillsLoaderTimer?.cancel();
    _existingSkillsLoaderTimer = null;
    _showOverviewAfterLoader = false;

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
                            onTap: () {
                              final GoRouter router = GoRouter.of(context);
                              if (router.canPop()) {
                                context.pop();
                              } else {
                                context.go(AppRouter.individualIdentityPath);
                              }
                            },
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
                              'Personal Info Preview',
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
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: s(12),
                              vertical: s(7),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(s(18)),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              'Edit',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: s(12),
                                fontWeight: FontWeight.w700,
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.fromLTRB(
                                    s(16),
                                    s(32),
                                    s(16),
                                    s(24),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Review your personal information',
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
                                        'You can preview, edit, and complete the details that will be used before starting your skill tree.',
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
                                      _EditableSectionCard(
                                        scale: scale,
                                        title: 'Personal Details',
                                        subtitle:
                                            'Make changes before you begin building the skill tree.',
                                        child: Column(
                                          children: <Widget>[
                                            _LabeledField(
                                              scale: scale,
                                              label: 'Full Name',
                                              child: TextFormField(
                                                controller: _fullName,
                                                decoration: _decoration(
                                                  hint: 'Enter your full name',
                                                ),
                                                validator: (String? value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'Full name is required.';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            SizedBox(height: s(14)),
                                            _LabeledField(
                                              scale: scale,
                                              label: 'Official Email',
                                              child: TextFormField(
                                                controller: _email,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                decoration: _decoration(
                                                  hint: 'Enter your email',
                                                ),
                                                validator: (String? value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'Email is required.';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            SizedBox(height: s(14)),
                                            _LabeledField(
                                              scale: scale,
                                              label: 'Mobile Number',
                                              child: TextFormField(
                                                controller: _mobile,
                                                keyboardType:
                                                    TextInputType.phone,
                                                decoration: _decoration(
                                                  hint: 'Enter mobile number',
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: s(14)),
                                            _LabeledField(
                                              scale: scale,
                                              label: 'Industry',
                                              child: TextFormField(
                                                controller: _industry,
                                                decoration: _decoration(
                                                  hint: 'Enter your industry',
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: s(14)),
                                            _LabeledField(
                                              scale: scale,
                                              label: 'Address',
                                              child: TextFormField(
                                                controller: _address,
                                                maxLines: 3,
                                                minLines: 3,
                                                textAlignVertical:
                                                    TextAlignVertical.top,
                                                decoration: _decoration(
                                                  hint: 'Enter your address',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: s(16)),
                                      _EditableSectionCard(
                                        scale: scale,
                                        title: 'What happens next',
                                        subtitle:
                                            'After this preview, we will take you into the skill-tree builder.',
                                        child: Column(
                                          children: <Widget>[
                                            _NextStepTile(
                                              scale: scale,
                                              icon:
                                                  Icons.addchart_rounded,
                                              title:
                                                  'Start with Technical Skills',
                                              subtitle:
                                                  'Add your first skill group and repeat it as many times as needed.',
                                            ),
                                            SizedBox(height: s(12)),
                                            _NextStepTile(
                                              scale: scale,
                                              icon:
                                                  Icons.layers_rounded,
                                              title:
                                                  'Build multiple sections',
                                              subtitle:
                                                  'Move through soft skills, education, experience, and achievements.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _BottomNav(
                                scale: scale,
                                child: _PrimaryButton(
                                  scale: scale,
                                  label: 'Start Making Skill Tree',
                                  onTap: _startSkillTree,
                                ),
                              ),
                            ],
                          ),
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

class _EditableSectionCard extends StatelessWidget {
  const _EditableSectionCard({
    required this.scale,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final double scale;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
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
          SizedBox(height: s(4)),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(11),
              fontWeight: FontWeight.w500,
              height: 16 / 11,
              color: const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: s(14)),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.scale,
    required this.label,
    required this.child,
  });

  final double scale;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: s(11),
            fontWeight: FontWeight.w700,
            letterSpacing: s(0.7),
            color: const Color(0xFF64748B),
          ),
        ),
        SizedBox(height: s(8)),
        child,
      ],
    );
  }
}

class _NextStepTile extends StatelessWidget {
  const _NextStepTile({
    required this.scale,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final double scale;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: s(40),
            height: s(40),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(s(12)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.brandBlue, size: s(20)),
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
                    fontSize: s(13),
                    fontWeight: FontWeight.w700,
                    height: 19 / 13,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: s(3)),
                Text(
                  subtitle,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s(13.604), s(12.864), s(13.668), s(12.864)),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(204),
        border: Border(
          top: BorderSide(color: const Color(0xFFF3F4F6), width: s(1.072)),
        ),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
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
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(17),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
