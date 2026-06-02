import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class FlowStepProgress extends StatelessWidget {
  const FlowStepProgress({
    super.key,
    required this.scale,
    required this.stepLabel,
    required this.progressLabel,
    required this.fillFactor,
  });

  final double scale;
  final String stepLabel;
  final String progressLabel;
  final double fillFactor;

  @override
  Widget build(BuildContext context) {
    double s(double v) => v * scale;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              stepLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(10),
                fontWeight: FontWeight.w700,
                letterSpacing: s(1),
                height: 15 / 10,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const Spacer(),
            Text(
              progressLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: s(10),
                fontWeight: FontWeight.w700,
                height: 15 / 10,
                color: AppColors.brandBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: s(8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(s(9999)),
          child: SizedBox(
            height: s(4),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillFactor.clamp(0, 1),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.brandBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
