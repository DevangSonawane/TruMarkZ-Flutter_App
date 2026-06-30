import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/auth_models.dart';
import '../../../../../core/models/skill_tree_models.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/tmz_badge.dart';
import '../../../../../core/services/token_storage.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/application/auth_state.dart';
import '../../data/skill_tree_repository.dart';

class IndividualSkillTreeOverviewPage extends ConsumerStatefulWidget {
  const IndividualSkillTreeOverviewPage({super.key});

  @override
  ConsumerState<IndividualSkillTreeOverviewPage> createState() =>
      _IndividualSkillTreeOverviewPageState();
}

class _IndividualSkillTreeOverviewPageState
    extends ConsumerState<IndividualSkillTreeOverviewPage>
    with TickerProviderStateMixin {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  late final AnimationController _pulseController;
  late final AnimationController _refreshController;
  bool _deletingAll = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _goBack() {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.individualIdentityPath);
    }
  }

  Future<void> _refresh() async {
    _refreshController.forward(from: 0);
    ref.invalidate(mySkillsProvider);
  }

  Future<void> _deleteAllSkills() async {
    if (_deletingAll) return;
    final bool confirmed = await _confirmDanger(
      title: 'Delete all skills',
      message:
          'This will delete your entire skill tree and all uploaded documents.',
      actionLabel: 'Delete all',
    );
    if (!confirmed) return;

    setState(() => _deletingAll = true);
    try {
      await ref.read(skillTreeRepositoryProvider).deleteAllSkills();
      await ref.read(tokenStorageProvider).saveSkillTreeCompleted(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All skills deleted.')));
      ref.invalidate(mySkillsProvider);
      context.go(AppRouter.individualScanPath);
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
      if (mounted) setState(() => _deletingAll = false);
    }
  }

  Future<bool> _confirmDanger({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  SkillTreeSkillType _skillTypeOf(SkillItem item) {
    return skillTypeFromValue(item.skillType);
  }

  String _displayName(UserProfile? profile) {
    final String? name = profile?.fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'there';
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<SkillsMeResponse> skillsAsync = ref.watch(
      mySkillsProvider,
    );
    final AsyncValue<AuthState> authAsync = ref.watch(authNotifierProvider);

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
                            onTap: _goBack,
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
                              'Your Skill Tree',
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
                            onTap: _refresh,
                            radius: s(20),
                            child: Container(
                              width: s(34),
                              height: s(34),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(s(12)),
                              ),
                              alignment: Alignment.center,
                              child: AnimatedBuilder(
                                animation: _refreshController,
                                builder: (BuildContext context, Widget? child) {
                                  return Transform.rotate(
                                    angle:
                                        _refreshController.value *
                                        6.283185307179586,
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  Icons.refresh_rounded,
                                  size: s(18),
                                  color: Colors.white,
                                ),
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
                          loading: () => Center(
                            child: SizedBox(
                              width: s(36),
                              height: s(36),
                              child: const CircularProgressIndicator(),
                            ),
                          ),
                          error: (Object error, StackTrace stackTrace) {
                            final String message = error is ApiException
                                ? error.message
                                : 'Unable to load your skills.';
                            return SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                s(16),
                                s(24),
                                s(16),
                                s(24),
                              ),
                              child: _NoticeCard(
                                scale: scale,
                                title: 'Could not load your skill tree',
                                message: message,
                                actionLabel: 'Try again',
                                onAction: _refresh,
                              ),
                            );
                          },
                          data: (SkillsMeResponse data) {
                            if (data.skills.isEmpty) {
                              return SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  s(16),
                                  s(24),
                                  s(16),
                                  s(24),
                                ),
                                child: _NoticeCard(
                                  scale: scale,
                                  title: 'No skills yet',
                                  message:
                                      'Start your skill tree from the builder and it will appear here once saved.',
                                  actionLabel: 'Start skill tree',
                                  onAction: () => context.go(
                                    AppRouter.individualSkillTreeBuildPath,
                                  ),
                                ),
                              );
                            }

                            final Map<SkillTreeSkillType, List<SkillItem>>
                            grouped = <SkillTreeSkillType, List<SkillItem>>{
                              for (final SkillTreeSkillType type
                                  in SkillTreeSkillType.values)
                                type: data.skills
                                    .where(
                                      (SkillItem skill) =>
                                          _skillTypeOf(skill) == type,
                                    )
                                    .toList(),
                            };
                            final int pendingCount = data.skills
                                .where(
                                  (SkillItem skill) =>
                                      skill.status.trim().toLowerCase() ==
                                      'pending',
                                )
                                .length;
                            final int verifiedCount = data.skills
                                .where(
                                  (SkillItem skill) =>
                                      skill.status.trim().toLowerCase() ==
                                      'verified',
                                )
                                .length;
                            final String displayName = _displayName(
                              authAsync.value?.userProfile,
                            );
                            final Map<SkillTreeSkillType, int> verifiedByType =
                                <SkillTreeSkillType, int>{
                                  for (final SkillTreeSkillType type
                                      in SkillTreeSkillType.values)
                                    type: (grouped[type] ?? <SkillItem>[])
                                        .where(
                                          (SkillItem skill) =>
                                              skill.status
                                                  .trim()
                                                  .toLowerCase() ==
                                              'verified',
                                        )
                                        .length,
                                };
                            final bool allVerified =
                                data.total > 0 && verifiedCount == data.total;

                            return Column(
                              children: <Widget>[
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.fromLTRB(
                                      s(16),
                                      s(28),
                                      s(16),
                                      s(24),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        _PendingHero(
                                          scale: scale,
                                          pulse: _pulseController,
                                          allVerified: allVerified,
                                        ),
                                        SizedBox(height: s(20)),
                                        _SummaryCard(
                                          scale: scale,
                                          displayName: displayName,
                                          total: data.total,
                                          pendingCount: pendingCount,
                                          verifiedCount: verifiedCount,
                                          allVerified: allVerified,
                                        ),
                                        SizedBox(height: s(16)),
                                        for (final SkillTreeSkillType type
                                            in SkillTreeSkillType
                                                .values) ...<Widget>[
                                          _SkillGroupCard(
                                            scale: scale,
                                            type: type,
                                            skills:
                                                grouped[type] ?? <SkillItem>[],
                                            verifiedCount:
                                                verifiedByType[type] ?? 0,
                                            onTap: () => context.push(
                                              '${AppRouter.individualSkillTreeDetailPath}?type=${Uri.encodeComponent(type.value)}',
                                            ),
                                          ),
                                          SizedBox(height: s(12)),
                                        ],
                                        SizedBox(height: s(6)),
                                      ],
                                    ),
                                  ),
                                ),
                                _BottomActions(
                                  scale: scale,
                                  primaryLabel: _deletingAll
                                      ? 'Deleting...'
                                      : 'Delete All Skills',
                                  primaryOnTap: _deletingAll
                                      ? () {}
                                      : _deleteAllSkills,
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

class _PendingHero extends StatelessWidget {
  const _PendingHero({
    required this.scale,
    required this.pulse,
    required this.allVerified,
  });

  final double scale;
  final AnimationController pulse;
  final bool allVerified;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (BuildContext context, Widget? child) {
          final double t = Curves.easeInOut.transform(pulse.value);
          return Transform.scale(scale: 1.0 + (t * 0.025), child: child);
        },
        child: Container(
          width: s(120),
          height: s(120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                const Color(0xFFD8E6FF),
                const Color(0xFFBFD3FF).withAlpha(140),
                const Color(0xFFF7F9FC),
              ],
              stops: const <double>[0.0, 0.68, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: s(90),
                height: s(90),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: allVerified ? AppColors.successBg : Colors.white,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: s(18),
                      offset: Offset(0, s(8)),
                    ),
                  ],
                ),
              ),
              Icon(
                allVerified ? Icons.check_rounded : Icons.hourglass_top_rounded,
                size: s(42),
                color: allVerified ? AppColors.success : AppColors.brandBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.scale,
    required this.displayName,
    required this.total,
    required this.pendingCount,
    required this.verifiedCount,
    required this.allVerified,
  });

  final double scale;
  final String displayName;
  final int total;
  final int pendingCount;
  final int verifiedCount;
  final bool allVerified;

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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
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
                  allVerified ? 'All skills verified' : 'Skill Tree',
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
                  allVerified
                      ? 'Everything in your skill tree has been verified.'
                      : 'Your skills are saved and waiting for review. Tap any category to open the detailed skill list.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(12),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: s(14)),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatPill(
                        scale: scale,
                        compact: true,
                        label: 'Total',
                        value: total,
                      ),
                    ),
                    SizedBox(width: s(8)),
                    Expanded(
                      child: _StatPill(
                        scale: scale,
                        compact: true,
                        label: 'Pending',
                        value: pendingCount,
                      ),
                    ),
                    SizedBox(width: s(8)),
                    Expanded(
                      child: _StatPill(
                        scale: scale,
                        compact: true,
                        label: 'Verified',
                        value: verifiedCount,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: s(14)),
                allVerified
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: s(12),
                          vertical: s(8),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(s(999)),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          'ALL VERIFIED',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: s(11),
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          SizedBox(width: s(12)),
          TMZBadge.pending(label: 'PENDING'),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.scale,
    required this.label,
    required this.value,
    this.compact = false,
  });

  final double scale;
  final String label;
  final int value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      constraints: BoxConstraints(minHeight: s(30)),
      padding: EdgeInsets.symmetric(
        horizontal: s(compact ? 10 : 12),
        vertical: s(compact ? 7 : 8),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(999)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$label: $value',
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(compact ? 10.5 : 11),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.scale,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final double scale;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

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
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(14),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: s(8)),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: const Color(0xFF475569),
            ),
          ),
          SizedBox(height: s(12)),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _SkillGroupCard extends StatelessWidget {
  const _SkillGroupCard({
    required this.scale,
    required this.type,
    required this.skills,
    required this.verifiedCount,
    required this.onTap,
  });

  final double scale;
  final SkillTreeSkillType type;
  final List<SkillItem> skills;
  final int verifiedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final int total = skills.length;
    final bool allVerified = total > 0 && verifiedCount == total;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(s(18)),
          child: Ink(
            padding: EdgeInsets.all(s(14)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(s(18)),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: s(52),
                  height: s(52),
                  decoration: BoxDecoration(
                    color: AppColors.blueTint,
                    borderRadius: BorderRadius.circular(s(16)),
                  ),
                  child: Icon(
                    _iconForType(type),
                    color: AppColors.brandBlue,
                    size: s(24),
                  ),
                ),
                SizedBox(width: s(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        type.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(16),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: s(3)),
                      Text(
                        type.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(11),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: s(12)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (allVerified)
                      Container(
                        width: s(28),
                        height: s(28),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(s(999)),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: s(18),
                          color: AppColors.success,
                        ),
                      )
                    else
                      Text(
                        '$verifiedCount/$total',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(15),
                          fontWeight: FontWeight.w800,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    SizedBox(height: s(4)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: s(8),
                        vertical: s(4),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(s(999)),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '$total skills',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(10),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.scale,
    required this.primaryLabel,
    required this.primaryOnTap,
  });

  final double scale;
  final String primaryLabel;
  final VoidCallback primaryOnTap;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s(13.604), s(12.864), s(13.668), s(12.864)),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(204),
        border: const Border(
          top: BorderSide(color: Color(0xFFF3F4F6), width: 1.072),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: s(60),
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(s(16)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(s(16)),
                    onTap: primaryOnTap,
                    child: Center(
                      child: Text(
                        primaryLabel,
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
            ),
            SizedBox(height: s(10)),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(SkillTreeSkillType type) {
  switch (type) {
    case SkillTreeSkillType.technical:
      return Icons.code_rounded;
    case SkillTreeSkillType.soft:
      return Icons.groups_rounded;
    case SkillTreeSkillType.education:
      return Icons.school_rounded;
    case SkillTreeSkillType.project:
      return Icons.work_outline_rounded;
  }
}
