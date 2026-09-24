import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

void showSignupOptionsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(120),
    elevation: 0,
    builder: (BuildContext sheetContext) {
      final double bottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;

      void open(String path) {
        Navigator.of(sheetContext).pop();
        context.go(path);
      }

      int selectedIndex = 0;
      String pathFor(int index) => index == 0
          ? '${AppRouter.registerPath}?force=true'
          : AppRouter.organisationRegistrationPath;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return SizedBox(
            height: 225 + bottomInset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withAlpha(34),
                    blurRadius: 34,
                    offset: const Offset(0, -12),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  AppSpacing.x4,
                  AppSpacing.x5,
                  AppSpacing.x5 + bottomInset,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Who are you?',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Choose between your two roles',
                      textAlign: TextAlign.center,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 130,
                              child: _SignupChoiceCard(
                                label: 'Individual',
                                selected: selectedIndex == 0,
                                onTap: () {
                                  if (selectedIndex == 0) {
                                    open(pathFor(0));
                                  } else {
                                    setSheetState(() => selectedIndex = 0);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.x3),
                            SizedBox(
                              width: 130,
                              child: _SignupChoiceCard(
                                label: 'Organisation',
                                selected: selectedIndex == 1,
                                onTap: () {
                                  if (selectedIndex == 1) {
                                    open(pathFor(1));
                                  } else {
                                    setSheetState(() => selectedIndex = 1);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _SignupChoiceCard extends StatelessWidget {
  const _SignupChoiceCard({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  static const Color _selectedColor = Color(0xFF1B3387);

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _selectedColor : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? _selectedColor : AppColors.textSecondary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
