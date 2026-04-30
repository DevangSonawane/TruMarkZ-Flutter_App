import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class BatchJobRunningPage extends StatefulWidget {
  const BatchJobRunningPage({super.key});

  @override
  State<BatchJobRunningPage> createState() => _BatchJobRunningPageState();
}

class _BatchJobRunningPageState extends State<BatchJobRunningPage> {
  double _progress = 0.12;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    // Simulated background work for the PRD step. Replace with real job tracking later.
    const List<Duration> steps = <Duration>[
      Duration(milliseconds: 600),
      Duration(milliseconds: 700),
      Duration(milliseconds: 800),
    ];
    const List<double> targets = <double>[0.35, 0.68, 1.0];

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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String batchName =
        (GoRouterState.of(context).uri.queryParameters['batch'] ?? 'New Batch')
            .trim()
            .isNotEmpty
        ? GoRouterState.of(context).uri.queryParameters['batch']!.trim()
        : 'New Batch';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/icons/trumarkz_shield.svg',
              height: 22,
              colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
            ),
            const SizedBox(width: AppSpacing.x2),
            const Text('Generating Credentials'),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x4),
          children: <Widget>[
            Text('Background batch job runs', style: AppTypography.display2),
            const SizedBox(height: AppSpacing.x2),
            Text(
              'We are running automated API checks and assigning human checks to verifiers. This usually takes a moment.',
              style: AppTypography.body2.copyWith(
                color: scheme.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            TMZCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(batchName, style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.x2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: scheme.onSurface.withAlpha(10),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.brandBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    '${(_progress * 100).round()}% complete',
                    style: AppTypography.caption.copyWith(
                      color: scheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            _JobStep(
              title: 'API Checks (Auto)',
              subtitle: 'Aadhaar, PAN, DL, Education, Employment',
              state: _progress >= 0.35
                  ? _JobState.runningOrDone
                  : _JobState.pending,
              done: _progress >= 0.68,
            ),
            const SizedBox(height: AppSpacing.x3),
            _JobStep(
              title: 'Human Checks (Assigned)',
              subtitle: 'Assigned to verifier agency by Super Admin',
              state: _progress >= 0.68
                  ? _JobState.runningOrDone
                  : _JobState.pending,
              done: _progress >= 1.0,
            ),
            const SizedBox(height: AppSpacing.x6),
            TMZButton(
              label: 'View Success',
              icon: Icons.check_circle_rounded,
              variant: TMZButtonVariant.secondary,
              onPressed: () => _goToSuccess(replace: false),
            ),
          ],
        ),
      ),
    );
  }
}

enum _JobState { pending, runningOrDone }

class _JobStep extends StatelessWidget {
  const _JobStep({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.done,
  });

  final String title;
  final String subtitle;
  final _JobState state;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color iconColor = done
        ? AppColors.success
        : (state == _JobState.pending
              ? scheme.onSurface.withAlpha(110)
              : AppColors.brandBlue);

    final IconData icon = done
        ? Icons.check_circle_rounded
        : (state == _JobState.pending
              ? Icons.hourglass_bottom_rounded
              : Icons.autorenew_rounded);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withAlpha(160)),
      ),
      padding: const EdgeInsets.all(AppSpacing.x4),
      child: Row(
        children: <Widget>[
          Icon(icon, color: iconColor),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.body2.copyWith(
                    color: scheme.onSurface.withAlpha(160),
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
