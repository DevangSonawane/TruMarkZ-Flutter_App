import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/tmz_badge.dart';
import '../../../../../core/widgets/tmz_button.dart';
import '../../../../../core/widgets/tmz_card.dart';

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({super.key});

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

enum PendingApprovalStatus { waiting, approved, rejected }

class _PendingApprovalPageState extends State<PendingApprovalPage>
    with TickerProviderStateMixin {
  static const Duration _demoApproveDelay = Duration(seconds: 2);
  static const Duration _demoRedirectDelay = Duration(milliseconds: 900);

  late final AnimationController _pulseController;
  late final AnimationController _rotateController;

  bool _initialized = false;
  PendingApprovalStatus _status = PendingApprovalStatus.waiting;
  String _orgName = 'Global Tech Ventures Inc.';
  String _email = 'admin@org.com';
  String? _rejectionReason;

  bool _autoFlowStarted = false;
  Future<void>? _autoFlowFuture;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _startDemoAutoFlow() async {
    if (_autoFlowStarted) return;
    _autoFlowStarted = true;

    await Future<void>.delayed(_demoApproveDelay);
    if (!mounted) return;
    if (_status != PendingApprovalStatus.waiting) return;
    setState(() => _status = PendingApprovalStatus.approved);

    await Future<void>.delayed(_demoRedirectDelay);
    if (!mounted) return;
    if (_status != PendingApprovalStatus.approved) return;
    context.go(AppRouter.dashboardPath);
  }

  Future<void> _checkStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    // Without a backend, we simulate the "refresh" pathway:
    // - waiting → approved
    // - rejected/approved remain as-is
    if (_status == PendingApprovalStatus.waiting) {
      setState(() => _status = PendingApprovalStatus.approved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    if (!_initialized) {
      _initialized = true;
      _status = _parseStatus(qp['status']);
      final String? orgRaw = qp['org'];
      if (orgRaw != null && orgRaw.trim().isNotEmpty) {
        _orgName = orgRaw.trim();
      }

      final String? emailRaw = qp['email'];
      if (emailRaw != null && emailRaw.trim().isNotEmpty) {
        _email = emailRaw.trim();
      }

      final String? reasonRaw = qp['reason'];
      _rejectionReason = (reasonRaw != null && reasonRaw.trim().isNotEmpty)
          ? reasonRaw.trim()
          : null;
    }

    // Demo behavior: auto-approve after a short "under review" pause, then
    // redirect to dashboard.
    if (_status == PendingApprovalStatus.waiting && _autoFlowFuture == null) {
      _autoFlowFuture = _startDemoAutoFlow();
    }

    final bool isWaiting = _status == PendingApprovalStatus.waiting;
    final bool isApproved = _status == PendingApprovalStatus.approved;
    final bool isRejected = _status == PendingApprovalStatus.rejected;

    final String title = switch (_status) {
      PendingApprovalStatus.waiting => 'Under Review',
      PendingApprovalStatus.approved => "You're approved!",
      PendingApprovalStatus.rejected => 'Registration not approved',
    };

    final String subtitle = switch (_status) {
      PendingApprovalStatus.waiting =>
        "Your organisation is under review.\nWe'll notify you by email within 24 hours.\nCheck back here or wait for the email.",
      PendingApprovalStatus.approved =>
        'Your organisation account is now active.',
      PendingApprovalStatus.rejected =>
        _rejectionReason == null
            ? 'Your registration was not approved.'
            : 'Reason: $_rejectionReason',
    };

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 22,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('TruMarkZ'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Check status',
            onPressed: _checkStatus,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkStatus,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x4,
            AppSpacing.x5,
            AppSpacing.x6,
          ),
          children: <Widget>[
            const SizedBox(height: AppSpacing.x4),
            Center(
              child: _StatusAnimation(
                status: _status,
                pulse: _pulseController,
                rotate: _rotateController,
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.heading1.copyWith(
                fontSize: 24,
                color: const Color(0xFF0B0F19),
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: scheme.onSurface.withAlpha(160),
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            TMZCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        Expanded(
                          child: Text(
                            'SUBMISSION SUMMARY',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x2),
                        if (isWaiting) TMZBadge.pending(label: 'PENDING'),
                        if (isApproved)
                          const TMZBadge(
                            label: 'APPROVED',
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        if (isRejected)
                          const TMZBadge(
                            label: 'REJECTED',
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      _orgName,
                      style: AppTypography.heading2.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'ID: TRM-8829-QX',
                      style: AppTypography.body2.copyWith(
                        color: scheme.onSurface.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _InfoPair(
                            label: 'Entity Type',
                            value: 'Private Limited',
                          ),
                        ),
                        Expanded(
                          child: _InfoPair(
                            label: 'Submitted On',
                            value: 'Oct 24, 2023',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    _AttachmentTile(
                      fileName: 'GST_Certificate.pdf',
                      onTap: () {},
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _AttachmentTile(fileName: 'Business_Reg.pdf', onTap: () {}),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      'Notifications will be sent to ${_maskEmail(_email)}',
                      style: AppTypography.caption.copyWith(
                        color: scheme.onSurface.withAlpha(140),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            TMZButton(
              label: switch (_status) {
                PendingApprovalStatus.waiting => 'Awaiting Approval',
                PendingApprovalStatus.approved => 'Go to Dashboard',
                PendingApprovalStatus.rejected => 'Re-submit',
              },
              onPressed: switch (_status) {
                PendingApprovalStatus.waiting => null,
                PendingApprovalStatus.approved => () => context.go(
                  AppRouter.dashboardPath,
                ),
                PendingApprovalStatus.rejected => () => context.go(
                  AppRouter.organisationRegistrationPath,
                ),
              },
            ),
            const SizedBox(height: AppSpacing.x3),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRouter.loginPath),
                child: Text(
                  'Log Out',
                  style: AppTypography.body2.copyWith(
                    color: scheme.onSurface.withAlpha(160),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static PendingApprovalStatus _parseStatus(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'approved':
        return PendingApprovalStatus.approved;
      case 'rejected':
        return PendingApprovalStatus.rejected;
      case 'waiting':
      default:
        return PendingApprovalStatus.waiting;
    }
  }

  static String _maskEmail(String email) {
    final int at = email.indexOf('@');
    if (at <= 1) return email;
    final String name = email.substring(0, at);
    final String domain = email.substring(at + 1);
    final String prefix = name.substring(0, 2);
    return '$prefix***@$domain';
  }
}

class _StatusAnimation extends StatelessWidget {
  const _StatusAnimation({
    required this.status,
    required this.pulse,
    required this.rotate,
  });

  final PendingApprovalStatus status;
  final AnimationController pulse;
  final AnimationController rotate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final Widget icon = switch (status) {
      PendingApprovalStatus.waiting => AnimatedBuilder(
        animation: rotate,
        builder: (BuildContext context, Widget? child) {
          return Transform.rotate(
            angle: rotate.value * 6.283185307179586,
            child: child,
          );
        },
        child: Icon(
          Icons.hourglass_top_rounded,
          color: scheme.primary,
          size: 34,
        ),
      ),
      PendingApprovalStatus.approved => AnimatedBuilder(
        animation: pulse,
        builder: (BuildContext context, Widget? child) {
          final double t = 0.96 + 0.04 * pulse.value;
          return Transform.scale(scale: t, child: child);
        },
        child: const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 38,
        ),
      ),
      PendingApprovalStatus.rejected => AnimatedBuilder(
        animation: pulse,
        builder: (BuildContext context, Widget? child) {
          final double t = 0.96 + 0.04 * pulse.value;
          return Transform.scale(scale: t, child: child);
        },
        child: const Icon(
          Icons.cancel_rounded,
          color: AppColors.error,
          size: 38,
        ),
      ),
    };

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary.withAlpha(70), width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: icon,
    );
  }
}

class _InfoPair extends StatelessWidget {
  const _InfoPair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: scheme.onSurface.withAlpha(140),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          value,
          style: AppTypography.body2.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.fileName, required this.onTap});

  final String fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: const Color(0xFFF5F7FF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x3,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.insert_drive_file_outlined,
                color: scheme.onSurface.withAlpha(160),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  fileName,
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Icon(
                Icons.remove_red_eye_outlined,
                size: 20,
                color: scheme.onSurface.withAlpha(160),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
