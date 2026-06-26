import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/auth_models.dart';
import '../../../../../core/models/skill_tree_models.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/tmz_badge.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import '../../data/skill_tree_repository.dart';

class IndividualSkillTreeDetailPage extends ConsumerWidget {
  const IndividualSkillTreeDetailPage({super.key});

  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  SkillTreeSkillType _selectedType(BuildContext context) {
    final String raw = GoRouterState.of(context).uri.queryParameters['type'] ??
        SkillTreeSkillType.technical.value;
    return skillTypeFromValue(raw);
  }

  String _displayName(UserProfile? profile) {
    final String? name = profile?.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'there';
  }

  void _goBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.individualScanPath);
    }
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(mySkillsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SkillsMeResponse> skillsAsync = ref.watch(mySkillsProvider);
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);
    final SkillTreeSkillType selectedType = _selectedType(context);

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
                      padding: EdgeInsets.fromLTRB(s(16), s(10), s(16), 0),
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
                              '${selectedType.label} Skills',
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
                          InkResponse(
                            onTap: () => _refresh(ref),
                            radius: s(20),
                            child: Container(
                              width: s(34),
                              height: s(34),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(s(12)),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.refresh_rounded,
                                size: s(18),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: s(18)),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _panelBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(s(20)),
                          ),
                        ),
                        child: skillsAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (Object error, StackTrace stackTrace) {
                            final String message = 'Unable to load your skills.';
                            return Center(
                              child: Padding(
                                padding: EdgeInsets.all(s(18)),
                                child: Text(
                                  message,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                          data: (SkillsMeResponse data) {
                            final List<SkillItem> skills = data.skills
                                .where(
                                  (SkillItem skill) =>
                                      skillTypeFromValue(skill.skillType) ==
                                      selectedType,
                                )
                                .toList();
                            final String displayName =
                                _displayName(authAsync.value?.userProfile);

                            return Column(
                              children: <Widget>[
                                Expanded(
                                  child: CustomScrollView(
                                    slivers: <Widget>[
                                      SliverPadding(
                                        padding: EdgeInsets.fromLTRB(
                                          s(16),
                                          s(28),
                                          s(16),
                                          s(20),
                                        ),
                                        sliver: SliverToBoxAdapter(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              _DetailHero(
                                                scale: scale,
                                                displayName: displayName,
                                                selectedType: selectedType,
                                                total: skills.length,
                                              ),
                                              SizedBox(height: s(16)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (skills.isEmpty)
                                        SliverPadding(
                                          padding: EdgeInsets.fromLTRB(
                                            s(16),
                                            0,
                                            s(16),
                                            s(24),
                                          ),
                                          sliver: SliverToBoxAdapter(
                                            child: _EmptyState(
                                              scale: scale,
                                              selectedType: selectedType,
                                            ),
                                          ),
                                        )
                                      else
                                        SliverPadding(
                                          padding: EdgeInsets.fromLTRB(
                                            s(16),
                                            0,
                                            s(16),
                                            s(24),
                                          ),
                                          sliver: SliverList.separated(
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              return _SkillDetailCard(
                                                scale: scale,
                                                skill: skills[index],
                                              );
                                            },
                                            separatorBuilder:
                                                (BuildContext context,
                                                    int index) {
                                              return SizedBox(height: s(12));
                                            },
                                            itemCount: skills.length,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
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

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.scale,
    required this.displayName,
    required this.selectedType,
    required this.total,
  });

  final double scale;
  final String displayName;
  final SkillTreeSkillType selectedType;
  final int total;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(20)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Hello, $displayName',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w700,
              color: AppColors.brandBlue,
            ),
          ),
          SizedBox(height: s(8)),
          Text(
            selectedType.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(24),
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: s(10)),
          Text(
            '${selectedType.label} in one place',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: s(14)),
          Text(
            'Review your ${selectedType.label.toLowerCase()} skills, documents, and verification status here.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: s(14)),
          TMZBadge.pending(label: total > 0 ? 'PENDING' : 'EMPTY'),
        ],
      ),
    );
  }
}

class _SkillDetailCard extends StatelessWidget {
  const _SkillDetailCard({
    required this.scale,
    required this.skill,
  });

  final double scale;
  final SkillItem skill;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final Color statusBg = _statusBg(skill.status);
    final Color statusFg = _statusFg(skill.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      skill.skillName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(14),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if ((skill.skillInfo ?? '').trim().isNotEmpty) ...<Widget>[
                      SizedBox(height: s(6)),
                      Text(
                        skill.skillInfo!.trim(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(12),
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                    if ((skill.institutionName ?? '').trim().isNotEmpty) ...<
                      Widget
                    >[
                      SizedBox(height: s(6)),
                      Text(
                        skill.degree?.trim().isNotEmpty == true
                            ? '${skill.institutionName!.trim()} • ${skill.degree!.trim()}'
                            : skill.institutionName!.trim(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(11),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(6)),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(s(999)),
                ),
                child: Text(
                  skill.status.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(10),
                    fontWeight: FontWeight.w800,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          if ((skill.statusReason ?? '').trim().isNotEmpty) ...<Widget>[
            SizedBox(height: s(8)),
            Text(
              skill.statusReason!.trim(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(11),
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ],
          SizedBox(height: s(12)),
          Wrap(
            spacing: s(8),
            runSpacing: s(8),
            children: <Widget>[
              if (skill.documents.isNotEmpty)
                for (final SkillDocument doc in skill.documents)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    label: Text(
                      '${doc.documentLabel?.trim().isNotEmpty == true ? doc.documentLabel!.trim() : 'Document'} v${doc.version}',
                    ),
                  )
              else
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  label: const Text('No documents yet'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.scale,
    required this.selectedType,
  });

  final double scale;
  final SkillTreeSkillType selectedType;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(s(18)),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'No ${selectedType.label.toLowerCase()} skills yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(14),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: s(8)),
          Text(
            'Once skills are added, their descriptions and documents will appear here.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusBg(String status) {
  switch (status.trim().toLowerCase()) {
    case 'verified':
      return AppColors.successBg;
    case 'rejected':
    case 'failed':
      return AppColors.dangerBg;
    case 'pending':
    default:
      return AppColors.blueTint;
  }
}

Color _statusFg(String status) {
  switch (status.trim().toLowerCase()) {
    case 'verified':
      return AppColors.success;
    case 'rejected':
    case 'failed':
      return AppColors.danger;
    case 'pending':
    default:
      return AppColors.brandBlue;
  }
}
