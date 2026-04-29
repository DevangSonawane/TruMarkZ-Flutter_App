import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class VerificationStepper extends StatelessWidget {
  const VerificationStepper({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.completedSteps,
  });

  final List<String> steps;
  final int currentStep;
  final Set<int> completedSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: List<Widget>.generate(steps.length, (int index) {
            final bool isCompleted = completedSteps.contains(index);
            final bool isCurrent = index == currentStep;
            final bool isActive = isCompleted || isCurrent;

            final Widget circle = _StepCircle(
              index: index,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
            );

            final Widget node = Column(
              children: <Widget>[
                circle,
                const SizedBox(height: AppSpacing.x2),
                SizedBox(
                  width: 70,
                  child: Text(
                    steps[index],
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            );

            if (index == steps.length - 1) return node;

            final Color lineColor =
                completedSteps.contains(index) ? AppColors.brandBlue : AppColors.silverGray;

            return Expanded(
              child: Row(
                children: <Widget>[
                  node,
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 22),
                      color: lineColor.withAlpha(204),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
  });

  final int index;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final Widget inner = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: (isCompleted || isCurrent) ? AppColors.brandBlue : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: (isCompleted || isCurrent) ? AppColors.brandBlue : AppColors.silverGray,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : Text(
              '${index + 1}',
              style: AppTypography.caption.copyWith(
                color: (isCompleted || isCurrent) ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );

    if (!isCurrent) return inner;

    return inner
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .boxShadow(
          duration: 900.ms,
          begin: const BoxShadow(
            color: Colors.transparent,
            blurRadius: 0,
            spreadRadius: 0,
          ),
          end: BoxShadow(
            color: AppColors.brandBlue.withAlpha(64),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        );
  }
}
