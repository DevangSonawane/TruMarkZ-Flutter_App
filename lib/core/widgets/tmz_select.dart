import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class TMZSelectOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  const TMZSelectOption({required this.value, required this.label, this.icon});
}

class TMZSelect<T> extends StatefulWidget {
  const TMZSelect({
    super.key,
    required this.label,
    required this.options,
    this.value,
    this.hint = 'Select an option',
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final List<TMZSelectOption<T>> options;
  final T? value;
  final String hint;
  final ValueChanged<T?>? onChanged;
  final bool enabled;

  @override
  State<TMZSelect<T>> createState() => _TMZSelectState<T>();
}

class _TMZSelectState<T> extends State<TMZSelect<T>> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final String displayLabel =
        widget.options
            .where((TMZSelectOption<T> o) => o.value == widget.value)
            .map((TMZSelectOption<T> o) => o.label)
            .firstOrNull ??
        '';

    final bool hasValue = displayLabel.trim().isNotEmpty;

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
            border: Border.all(color: AppColors.border, width: 1.25),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              splashColor: AppColors.brandBlue.withAlpha(0x0A),
              highlightColor: AppColors.brandBlue.withAlpha(0x06),
              onTap: widget.enabled ? () => _showPicker(context) : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 54),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          hasValue ? displayLabel : widget.hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: hasValue
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeOut,
                        child: Icon(
                          _open
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          key: ValueKey<bool>(_open),
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    setState(() => _open = true);
    try {
      final TMZSelectOption<T>? selected =
          await showModalBottomSheet<TMZSelectOption<T>>(
            context: context,
            useSafeArea: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return _TMZSelectSheet<T>(
                title: widget.label,
                options: widget.options,
                value: widget.value,
              );
            },
          );
      if (!mounted) return;
      if (selected != null) widget.onChanged?.call(selected.value);
    } finally {
      if (mounted) setState(() => _open = false);
    }
  }
}

class _TMZSelectSheet<T> extends StatelessWidget {
  const _TMZSelectSheet({
    required this.title,
    required this.options,
    required this.value,
  });

  final String title;
  final List<TMZSelectOption<T>> options;
  final T? value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 1, end: 0),
      builder: (BuildContext context, double t, Widget? child) {
        return Transform.translate(
          offset: Offset(0, 20 * t),
          child: Opacity(opacity: 1 - t, child: child),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.cardSurface),
          child: DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (BuildContext context, ScrollController controller) {
              return Column(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final TMZSelectOption<T> option = options[index];
                        final bool selected = option.value == value;
                        return Material(
                          color: selected
                              ? AppColors.blueTint
                              : Colors.transparent,
                          child: ListTile(
                            onTap: () => Navigator.of(context).pop(option),
                            leading: option.icon == null
                                ? null
                                : Icon(
                                    option.icon,
                                    color: selected
                                        ? AppColors.brandBlue
                                        : AppColors.textTertiary,
                                  ),
                            title: Text(
                              option.label,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            trailing: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.brandBlue,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
