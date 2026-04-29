import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class CredentialTemplateSelectorPage extends StatelessWidget {
  const CredentialTemplateSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

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
            const Text('Template Selector'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Choose a template', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x3),
          TMZCard(
            onTap: () => context.go(AppRouter.mapCredentialFieldsPath),
            child: const ListTile(
              leading: Icon(Icons.article_outlined),
              title: Text('T1 — Standard Identity'),
              subtitle: Text('Name, DOB, ID number, photo'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          const TMZCard(
            child: ListTile(
              leading: Icon(Icons.badge_outlined),
              title: Text('T2 — Employee Verification'),
              subtitle: Text('Employee ID, role, start date'),
              trailing: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          TMZButton(
            label: 'Continue with T1',
            onPressed: () => context.go(AppRouter.mapCredentialFieldsPath),
          ),
        ],
      ),
    );
  }
}

