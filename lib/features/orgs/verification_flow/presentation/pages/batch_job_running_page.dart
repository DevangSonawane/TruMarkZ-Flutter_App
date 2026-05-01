import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

class BatchJobRunningPage extends StatefulWidget {
  const BatchJobRunningPage({super.key});

  @override
  State<BatchJobRunningPage> createState() => _BatchJobRunningPageState();
}

class _BatchJobRunningPageState extends State<BatchJobRunningPage> {
  static const String _heroImageUrl =
      'https://lh3.googleusercontent.com/aida/ADBb0ugfgT1327qtmZBb5HCEWgfJ4VvfkZUxLItWYdnrVHewXjKqYhiYPXFxXtgZN0sYwzbJdhcN63zBAqEpwlIeEfTb3-1Ccv0U3IU7v6iVFB8wC1nr8dBCzLuUeTGH4VxwMSkH1HQUu4Fo6dJu3LhgK8L-rJuOmHBqZ4OTIY82JzuBFnrYv8Hqz8h9L65XZa7lULryoN9naurnlnCnNHf9tTY6-SqJW0sKuy6KrT55Q3IDQYF-rYBI3fRzxmOd584HnqfbRBrwvLtWLA';
  static const String _secondaryImageUrl =
      'https://lh3.googleusercontent.com/aida/ADBb0uhJBdF3vTRwoK3NOiP7nL3OPGX7zx5l-funeCyySeTy4MoTcHlrG4qr9G_e4YgprZedpjQeEiT3N5EJJVEmvhhYmTweTTInBuwQsTfUv5q6j0-n5iA-kwvqjDDvdbcI0TxCUy4MtZk73p07nZOb71uEoOvHsS-BRSY-Q6bJksc2U_V3o19JXBHAjKXV3UIp2-jt1uRtYNX10ZZjudf0QvXRtKyj6xnABsBNwOUd7mQhxqaUIe0BszW_FoGDvw5T39SvwJ3BS2QO1w';

  double _progress = 0.12;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // Simulated background work for the PRD step. Replace with real job tracking later.
    const List<Duration> steps = <Duration>[
      Duration(milliseconds: 500),
      Duration(milliseconds: 650),
      Duration(milliseconds: 700),
      Duration(milliseconds: 900),
    ];
    const List<double> targets = <double>[0.32, 0.54, 0.76, 1.0];

    for (int i = 0; i < steps.length; i++) {
      await Future<void>.delayed(steps[i]);
      if (!mounted) return;
      setState(() => _progress = targets[i]);
    }

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _goToSuccess(replace: true);
  }

  void _goToSuccess({required bool replace}) {
    final Map<String, String> qp = Map<String, String>.from(
      GoRouterState.of(context).uri.queryParameters,
    );
    qp.putIfAbsent('created', () => qp['records'] ?? '80');

    final String qs = qp.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final String location = qs.isEmpty
        ? AppRouter.credentialsGeneratedPath
        : '${AppRouter.credentialsGeneratedPath}?$qs';

    if (replace) {
      context.replace(location);
    } else {
      context.push(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    final String requestId = (qp['requestId'] ?? 'TRM-092-X12').trim().isNotEmpty
        ? qp['requestId']!.trim()
        : 'TRM-092-X12';

    final int pct = (_progress * 100).round().clamp(0, 100);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white.withAlpha(230),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: const Color(0xFF2563EB).withAlpha(16),
        leadingWidth: 140,
        leading: InkWell(
          onTap: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(width: 16),
              const Icon(Icons.arrow_back_rounded, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Text(
                'Batch Progress',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRouter.notificationsPath),
            icon: const Icon(
              Icons.notifications_rounded,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x4,
          AppSpacing.x4,
          110,
        ),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: <Widget>[
                  _SuccessCard(progress: _progress, percentLabel: '$pct%'),
                  const SizedBox(height: AppSpacing.x5),
                  _SecondaryInfoCard(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          Center(
            child: Text(
              'Metadata: Request ID #$requestId',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFF737686),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: 1,
        onTap: (int i) {
          switch (i) {
            case 0:
              context.go(AppRouter.dashboardPath);
              return;
            case 1:
              context.go(AppRouter.appBatchesPath);
              return;
            case 2:
              context.go(AppRouter.walletPath);
              return;
            case 3:
              context.go(AppRouter.settingsPath);
              return;
          }
        },
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.progress, required this.percentLabel});

  final double progress;
  final String percentLabel;

  @override
  Widget build(BuildContext context) {
    final bool dataValidationDone = progress >= 0.32;
    final bool photoMatchDone = progress >= 0.54;
    final bool generationDone = progress >= 0.76;
    final bool blockchainDone = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Template & Field Mapping Approved!',
            style: AppTypography.display2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.x2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.shield_rounded,
                  size: 18,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(width: 8),
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
          const SizedBox(height: AppSpacing.x4),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 0.83,
              child: Image.network(
                _BatchJobRunningPageState._heroImageUrl,
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation<double>(0.9),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Generating credentials for 10,000 records in background...',
                  style: AppTypography.body2.copyWith(
                    color: const Color(0xFF434655),
                    height: 1.25,
                  ),
                ),
              ),
              Text(
                percentLabel,
                style: AppTypography.heading1.copyWith(
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 12,
              color: const Color(0xFFEEF3FF),
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0, 1),
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        const Color(0xFF2563EB),
                        const Color(0xFF1E3A8A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          _StepRow(label: 'Data Validation', done: dataValidationDone),
          const SizedBox(height: AppSpacing.x3),
          _StepRow(label: 'Photo Matching (S3)', done: photoMatchDone),
          const SizedBox(height: AppSpacing.x3),
          _StepRow(label: 'Credential Generation', done: generationDone),
          const SizedBox(height: AppSpacing.x3),
          _StepRow(label: 'Blockchain Write (Dhiway)', done: blockchainDone),
          const SizedBox(height: AppSpacing.x3),
          _StepRow(
            label: 'Completion Notification',
            done: false,
            dimmed: !blockchainDone,
          ),
          const SizedBox(height: AppSpacing.x5),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go(AppRouter.appBatchesPath),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ).copyWith(
                backgroundColor: const WidgetStatePropertyAll<Color>(
                  Colors.transparent,
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFF2563EB),
                      Color(0xFF1E3A8A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    'View Live Dashboard',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.done, this.dimmed = false});

  final String label;
  final bool done;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Color bg = done ? const Color(0xFFD1FAE5) : const Color(0xFFE1E2ED);
    final Color fg = done ? const Color(0xFF059669) : const Color(0xFF737686);
    final IconData icon =
        done ? Icons.check_circle_rounded : Icons.radio_button_unchecked;

    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Row(
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: fg, size: 20),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Image.network(
                _BatchJobRunningPageState._secondaryImageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Background Task Active',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "You can safely close this screen. We'll notify you when generation is complete.",
                  style: AppTypography.body2.copyWith(
                    color: const Color(0xFF434655),
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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 10 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withAlpha(12))),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(16),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _NavItem(
            label: 'Home',
            icon: Icons.dashboard_rounded,
            active: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            label: 'Batches',
            icon: Icons.fact_check_rounded,
            active: currentIndex == 1,
            filled: true,
            onTap: () => onTap(1),
          ),
          _NavItem(
            label: 'Vault',
            icon: Icons.shield_rounded,
            active: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            label: 'Settings',
            icon: Icons.settings_rounded,
            active: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.brandBlue : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: color,
              fill: filled && active ? 1.0 : 0.0,
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            if (active) ...<Widget>[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.brandBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
