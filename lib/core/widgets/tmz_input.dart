import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class TMZInput extends StatefulWidget {
  const TMZInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.errorText,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  State<TMZInput> createState() => _TMZInputState();
}

class _TMZInputState extends State<TMZInput> {
  late final FocusNode _focusNode;
  bool _focused = false;
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    _obscure = widget.obscureText;
  }

  @override
  void didUpdateWidget(TMZInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscure = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focused == _focusNode.hasFocus) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = (widget.errorText ?? '').trim().isNotEmpty;
    final Color borderColor = hasError
        ? AppColors.error
        : _focused
        ? AppColors.brandBlue
        : AppColors.border;

    Widget? suffixWidget = widget.suffix;
    if (suffixWidget == null && widget.obscureText) {
      suffixWidget = IconButton(
        onPressed: widget.enabled
            ? () => setState(() => _obscure = !_obscure)
            : null,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            key: ValueKey<bool>(_obscure),
            size: 20,
          ),
        ),
        color: AppColors.textTertiary,
        splashRadius: 20,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label.trim().isNotEmpty) ...<Widget>[
          Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.enabled ? AppColors.cardSurface : AppColors.offWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: hasError ? 1 : 1.25),
            // Keep a single visible border (no outer focus ring).
            boxShadow: null,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Row(
              children: <Widget>[
                if (widget.prefixIcon != null) ...<Widget>[
                  const SizedBox(width: 12),
                  Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    obscureText: _obscure,
                    onChanged: widget.onChanged,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                      // AppTheme sets a global filled InputDecorationTheme; opt out here
                      // because this widget already draws its own container/background.
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.fromLTRB(
                        widget.prefixIcon == null ? 16 : 12,
                        16,
                        16,
                        16,
                      ),
                    ),
                  ),
                ),
                if (suffixWidget != null) ...<Widget>[
                  const SizedBox(width: 4),
                  suffixWidget,
                  const SizedBox(width: 4),
                ],
              ],
            ),
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}
