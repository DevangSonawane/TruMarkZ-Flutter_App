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
    with SingleTickerProviderStateMixin {
  static const double _referenceWidth = 402;
  static const Color _panelBg = Color(0xFFF7F9FC);

  late final AnimationController _pulseController;
  bool _deletingAll = false;
  final Set<String> _busySkillIds = <String>{};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    ref.invalidate(mySkillsProvider);
  }

  Future<void> _deleteSkill(SkillItem skill) async {
    if (_busySkillIds.contains(skill.id)) return;
    final bool confirmed = await _confirmDanger(
      title: 'Delete skill',
      message: 'Delete "${skill.skillName}" from your skill tree?',
      actionLabel: 'Delete',
    );
    if (!confirmed) return;

    setState(() => _busySkillIds.add(skill.id));
    try {
      await ref.read(skillTreeRepositoryProvider).deleteSkill(
        skillId: skill.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${skill.skillName}" deleted.')),
      );
      ref.invalidate(mySkillsProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busySkillIds.remove(skill.id));
    }
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All skills deleted.')),
      );
      ref.invalidate(mySkillsProvider);
      context.go(AppRouter.individualScanPath);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
    final AsyncValue<SkillsMeResponse> skillsAsync = ref.watch(mySkillsProvider);
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
                          loading: () => Center(
                            child: SizedBox(
                              width: s(36),
                              height: s(36),
                              child: const CircularProgressIndicator(),
                            ),
                          ),
                          error: (Object error, StackTrace stackTrace) {
                            final String message =
                                error is ApiException
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
                                type:
                                    data.skills
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
                            final String displayName =
                                _displayName(authAsync.value?.userProfile);

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
                                        _PendingHero(scale: scale, pulse: _pulseController),
                                        SizedBox(height: s(20)),
                                        _SummaryCard(
                                          scale: scale,
                                          displayName: displayName,
                                          total: data.total,
                                          pendingCount: pendingCount,
                                          verifiedCount: verifiedCount,
                                        ),
                                        SizedBox(height: s(16)),
                                        for (final SkillTreeSkillType type
                                            in SkillTreeSkillType.values) ...<
                                          Widget
                                        >[
                                          _SkillGroupCard(
                                            scale: scale,
                                            type: type,
                                            skills: grouped[type] ??
                                                <SkillItem>[],
                                            busySkillIds: _busySkillIds,
                                            onEditSkill: (_) => context.push(
                                              AppRouter.individualSkillTreeBuildPath,
                                            ),
                                            onDeleteSkill: _deleteSkill,
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
  });

  final double scale;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Center(
      child: AnimatedBuilder(
        animation: pulse,
        builder: (BuildContext context, Widget? child) {
          final double t = Curves.easeInOut.transform(pulse.value);
          return Transform.scale(
            scale: 1.0 + (t * 0.025),
            child: child,
          );
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
                  color: Colors.white,
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
                Icons.hourglass_top_rounded,
                size: s(42),
                color: AppColors.brandBlue,
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
  });

  final double scale;
  final String displayName;
  final int total;
  final int pendingCount;
  final int verifiedCount;

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
            'Pending skill tree',
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
            'Your skills are saved and waiting for review. Edit or remove items as needed while the tree is pending.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: s(12),
              fontWeight: FontWeight.w500,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: s(14)),
          Wrap(
            spacing: s(8),
            runSpacing: s(8),
            children: <Widget>[
              _StatPill(scale: scale, label: 'Total', value: total),
              _StatPill(scale: scale, label: 'Pending', value: pendingCount),
              _StatPill(scale: scale, label: 'Verified', value: verifiedCount),
            ],
          ),
          SizedBox(height: s(14)),
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
  });

  final double scale;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(12), vertical: s(8)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(999)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: s(11),
          fontWeight: FontWeight.w700,
          color: const Color(0xFF334155),
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
          FilledButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
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
    required this.busySkillIds,
    required this.onEditSkill,
    required this.onDeleteSkill,
  });

  final double scale;
  final SkillTreeSkillType type;
  final List<SkillItem> skills;
  final Set<String> busySkillIds;
  final ValueChanged<SkillItem> onEditSkill;
  final ValueChanged<SkillItem> onDeleteSkill;

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    SizedBox(height: s(2)),
                    Text(
                      type.description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: s(11),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: s(10), vertical: s(6)),
                decoration: BoxDecoration(
                  color: AppColors.blueTint,
                  borderRadius: BorderRadius.circular(s(999)),
                ),
                child: Text(
                  '${skills.length}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: s(11),
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s(12)),
          if (skills.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(s(12)),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(s(14)),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'No ${type.label.toLowerCase()} skills yet.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: s(12),
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            )
          else
            for (int i = 0; i < skills.length; i++) ...<Widget>[
              _SkillCard(
                scale: scale,
                skill: skills[i],
                busy: busySkillIds.contains(skills[i].id),
                onEdit: () => onEditSkill(skills[i]),
                onDelete: () => onDeleteSkill(skills[i]),
              ),
              if (i != skills.length - 1) SizedBox(height: s(10)),
            ],
        ],
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.scale,
    required this.skill,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final double scale;
  final SkillItem skill;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;
    final Color statusBg = _statusBg(skill.status);
    final Color statusFg = _statusFg(skill.status);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if ((skill.skillInfo ?? '').trim().isNotEmpty) ...<Widget>[
                      SizedBox(height: s(4)),
                      Text(
                        skill.skillInfo!.trim(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(11),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                    if ((skill.institutionName ?? '').trim().isNotEmpty) ...<
                      Widget
                    >[
                      SizedBox(height: s(4)),
                      Text(
                        skill.degree?.trim().isNotEmpty == true
                            ? '${skill.institutionName!.trim()} • ${skill.degree!.trim()}'
                            : skill.institutionName!.trim(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: s(11),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
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
            SizedBox(height: s(6)),
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
          SizedBox(height: s(10)),
          Wrap(
            spacing: s(8),
            runSpacing: s(8),
            children: <Widget>[
              if (skill.documents.isNotEmpty)
                for (final SkillDocument doc in skill.documents)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    label: Text(
                      '${doc.documentLabel?.trim().isNotEmpty == true ? doc.documentLabel!.trim() : 'Document'} v${doc.version}',
                    ),
                  )
              else
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  label: const Text('No documents yet'),
                ),
            ],
          ),
          SizedBox(height: s(10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                tooltip: 'Edit',
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: busy ? null : onDelete,
                icon: busy
                    ? SizedBox(
                        width: s(18),
                        height: s(18),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
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
      padding: EdgeInsets.fromLTRB(
        s(13.604),
        s(12.864),
        s(13.668),
        s(12.864),
      ),
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
