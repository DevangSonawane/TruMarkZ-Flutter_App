import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum TMZButtonVariant { primary, secondary, ghost, danger }

class TMZButton extends StatefulWidget {
  const TMZButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = TMZButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final TMZButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  @override
  State<TMZButton> createState() => _TMZButtonState();
}

class _TMZButtonState extends State<TMZButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    final Color foregroundColor = switch (widget.variant) {
      TMZButtonVariant.primary => Colors.white,
      TMZButtonVariant.secondary => AppColors.brandBlue,
      TMZButtonVariant.ghost => AppColors.brandBlue,
      TMZButtonVariant.danger => Colors.white,
    };

    final Color backgroundColor = switch (widget.variant) {
      TMZButtonVariant.primary => AppColors.brandBlue,
      TMZButtonVariant.secondary => Colors.white,
      TMZButtonVariant.ghost => Colors.transparent,
      TMZButtonVariant.danger => AppColors.error,
    };

    final BorderSide side = switch (widget.variant) {
      TMZButtonVariant.secondary => const BorderSide(color: AppColors.brandBlue),
      _ => BorderSide.none,
    };

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (widget.isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        else ...<Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(widget.icon, size: 18, color: foregroundColor),
            const SizedBox(width: 10),
          ],
          Text(
            widget.label,
            style: AppTypography.button.copyWith(color: foregroundColor),
          ),
        ],
      ],
    );

    final Widget button = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isDisabled ? 0.4 : 1.0,
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: isDisabled ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: side,
            ),
          ),
          child: content,
        ),
      ),
    );

    if (isDisabled) return button;

    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      onPointerUp: (_) => setState(() => _isPressed = false),
      child: button
          .animate(target: _isPressed ? 1 : 0)
          .scaleXY(end: 0.97, duration: 90.ms, curve: Curves.easeOut),
    );
  }
}
