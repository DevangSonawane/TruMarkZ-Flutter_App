import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

enum TMZButtonVariant { primary, ghost, dangerGhost, dangerFilled, secondary }

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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    final Color foregroundColor = switch (widget.variant) {
      TMZButtonVariant.primary => Colors.white,
      TMZButtonVariant.dangerFilled => Colors.white,
      TMZButtonVariant.dangerGhost => AppColors.error,
      TMZButtonVariant.ghost => AppColors.brandBlue,
      TMZButtonVariant.secondary => AppColors.brandBlue,
    };

    final Color? solidBackground = switch (widget.variant) {
      TMZButtonVariant.dangerFilled => AppColors.danger,
      TMZButtonVariant.ghost => Colors.white,
      TMZButtonVariant.dangerGhost => Colors.white,
      TMZButtonVariant.secondary => Colors.white,
      _ => null,
    };

    final BoxBorder? border = switch (widget.variant) {
      TMZButtonVariant.ghost => Border.all(
        color: AppColors.brandBlue,
        width: 1.5,
      ),
      TMZButtonVariant.dangerGhost => Border.all(
        color: AppColors.error,
        width: 1.5,
      ),
      TMZButtonVariant.secondary => Border.all(
        color: AppColors.border,
        width: 1.5,
      ),
      _ => null,
    };

    final List<BoxShadow> shadows = switch (widget.variant) {
      TMZButtonVariant.primary => <BoxShadow>[
        BoxShadow(
          color: AppColors.brandBlue.withAlpha(0x59),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      TMZButtonVariant.dangerFilled => <BoxShadow>[
        BoxShadow(
          color: AppColors.danger.withAlpha(38),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      _ => const <BoxShadow>[],
    };

    final bool showGradient = widget.variant == TMZButtonVariant.primary;

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: foregroundColor,
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(widget.icon, size: 18, color: foregroundColor),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
          ),
        ],
      );
    }

    final BorderRadius radius = BorderRadius.circular(16);
    final Widget base = AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isDisabled ? 0.45 : 1.0,
      child: Container(
        height: 54,
        width: widget.fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: showGradient ? null : solidBackground,
          gradient: showGradient
              ? const LinearGradient(
                  colors: <Color>[AppColors.brandBlue, AppColors.deepNavy],
                )
              : null,
          borderRadius: radius,
          border: border,
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: isDisabled ? null : widget.onPressed,
            onTapDown: isDisabled
                ? null
                : (_) => setState(() => _pressed = true),
            onTapUp: isDisabled
                ? null
                : (_) => setState(() => _pressed = false),
            onTapCancel: isDisabled
                ? null
                : () => setState(() => _pressed = false),
            borderRadius: radius,
            splashColor: Colors.white.withAlpha(31),
            highlightColor: Colors.white.withAlpha(18),
            child: Center(child: content),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: _pressed ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: base,
    );
  }
}
