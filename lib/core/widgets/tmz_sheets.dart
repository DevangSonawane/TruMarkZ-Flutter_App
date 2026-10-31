import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'tmz_button.dart';

/// App-styled confirmation bottom sheet. Resolves `true` only on confirm.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required IconData icon,
  required Color tone,
  required String title,
  required String message,
  required String confirmLabel,
  List<String> bullets = const <String>[],
}) async {
  final bool? result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    // Above the shell's floating bottom nav, not underneath it.
    useRootNavigator: true,
    builder: (BuildContext sheetContext) => _SheetBody(
      icon: icon,
      tone: tone,
      title: title,
      message: message,
      bullets: bullets,
      actions: <Widget>[
        TMZButton(
          label: confirmLabel,
          backgroundColor: tone,
          showShadow: false,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
        const SizedBox(height: AppSpacing.x2),
        TMZButton(
          label: 'Cancel',
          variant: TMZButtonVariant.secondary,
          onPressed: () => Navigator.of(sheetContext).pop(false),
        ),
      ],
    ),
  );
  return result == true;
}

/// App-styled information bottom sheet with a single "OK".
Future<void> showMessageSheet(
  BuildContext context, {
  required IconData icon,
  required Color tone,
  required String title,
  required String message,
  List<String> bullets = const <String>[],
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    // Above the shell's floating bottom nav, not underneath it.
    useRootNavigator: true,
    builder: (BuildContext sheetContext) => _SheetBody(
      icon: icon,
      tone: tone,
      title: title,
      message: message,
      bullets: bullets,
      actions: <Widget>[
        TMZButton(
          label: 'OK',
          showShadow: false,
          onPressed: () => Navigator.of(sheetContext).pop(),
        ),
      ],
    ),
  );
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    required this.bullets,
    required this.actions,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String message;
  final List<String> bullets;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tone, size: 26),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            if (bullets.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final String b in bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: tone,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ...actions,
          ],
        ),
      ),
    );
  }
}
