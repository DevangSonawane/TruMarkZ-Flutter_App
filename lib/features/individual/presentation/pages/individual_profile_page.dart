import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class IndividualProfilePage extends StatelessWidget {
  const IndividualProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color pageSurface = Color(0xFFFAF8FF);
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: pageSurface,
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.blueTint, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: <Widget>[
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.arrow_back,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'My Skill Tree',
                              style: AppTypography.heading1.copyWith(
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () {},
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.share_outlined,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(<Widget>[
                const _ProfileHeaderCard(),
                const SizedBox(height: 24),
                const _SectionCard(
                  title: 'Education',
                  items: <_SectionItemData>[
                    _SectionItemData(
                      icon: Icons.school_outlined,
                      title: 'M.S. Cyber Security',
                      subtitle: 'Stanford University • 2021',
                      status: _ItemStatus.verified,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionCard(
                  title: 'Experience',
                  items: <_SectionItemData>[
                    _SectionItemData(
                      icon: Icons.work_outline,
                      title: 'Senior Identity Architect',
                      subtitle: 'AuthGlobal Corp • 2021 – Present',
                      status: _ItemStatus.verified,
                    ),
                    _SectionItemData(
                      icon: Icons.work_outline,
                      title: 'Systems Analyst',
                      subtitle: 'TechNexus Solutions • 2018 – 2021',
                      status: _ItemStatus.pending,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionCard(
                  title: 'Certifications',
                  items: <_SectionItemData>[
                    _SectionItemData(
                      icon: Icons.workspace_premium_outlined,
                      title: 'CISSP Certification',
                      subtitle: 'ISC2 • Issued May 2022',
                      status: _ItemStatus.verified,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _AddAchievementCard(),
                const SizedBox(height: 24),
                _LogoutCard(onLogout: () => context.go(AppRouter.loginPath)),
                SizedBox(height: 84 + bottomInset),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x142563EB),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: AppColors.blueTint,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.brandBlue,
                      size: 44,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Alex Rivera',
            textAlign: TextAlign.center,
            style: AppTypography.display2.copyWith(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.blueTint,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD6E2FF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'TruMarkZ Verified',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
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

enum _ItemStatus { verified, pending }

class _SectionItemData {
  const _SectionItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _ItemStatus status;
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x142563EB),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Account',
            style: AppTypography.heading2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Log out to return to the login / signup screen.',
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onLogout,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              alignment: Alignment.center,
              child: Text(
                'Log out',
                style: AppTypography.body1.copyWith(
                  color: const Color(0xFFB91C1C),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.items});

  final String title;
  final List<_SectionItemData> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.edit_outlined, color: AppColors.textTertiary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x142563EB),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < items.length; i++) ...<Widget>[
                  _SectionItemRow(data: items[i]),
                  if (i != items.length - 1) ...<Widget>[
                    const SizedBox(height: 18),
                    Container(height: 1, color: const Color(0xFFF1F5F9)),
                    const SizedBox(height: 18),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionItemRow extends StatelessWidget {
  const _SectionItemRow({required this.data});

  final _SectionItemData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(data.icon, color: AppColors.brandBlue),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      data.title,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(status: data.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final _ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final bool verified = status == _ItemStatus.verified;
    final Color bg = verified ? AppColors.successBg : const Color(0xFFFFFBEB);
    final Color fg = verified ? const Color(0xFF047857) : AppColors.warning;
    final Color border = verified
        ? const Color(0xFFB7F7D0)
        : AppColors.warningBg;
    final IconData icon = verified
        ? Icons.check_circle
        : Icons.hourglass_bottom;
    final String label = verified ? 'Verified' : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAchievementCard extends StatelessWidget {
  const _AddAchievementCard();

  @override
  Widget build(BuildContext context) {
    const double radius = 24;
    return CustomPaint(
      painter: _DashedRoundedRectPainter(
        color: AppColors.border,
        strokeWidth: 2,
        radius: radius,
        dashLength: 8,
        dashGap: 6,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3FE),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFF0053DB), AppColors.brandBlue],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x332563EB),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'Add your next achievement',
                textAlign: TextAlign.center,
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  'Upload certificates or connect your professional accounts.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
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

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final Path path = Path()..addRRect(rrect);
    final PathMetrics metrics = path.computeMetrics();

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap;
  }
}
