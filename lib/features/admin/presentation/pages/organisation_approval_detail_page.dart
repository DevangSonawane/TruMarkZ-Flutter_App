import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_button.dart';
import '../../../../core/widgets/tmz_card.dart';

class OrganisationApprovalDetailPage extends StatelessWidget {
  const OrganisationApprovalDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 22),
            const SizedBox(width: AppSpacing.x2),
            const Text('Approval Detail'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Acme Corp', style: AppTypography.display2),
            const SizedBox(height: AppSpacing.x4),
            const TMZCard(
              child: ListTile(
                leading: Icon(Icons.business_rounded),
                title: Text('Organisation Registration'),
                subtitle: Text('Submitted documents and admin details'),
              ),
            ),
            const Spacer(),
            TMZButton(label: 'Approve', onPressed: () {}),
            const SizedBox(height: AppSpacing.x2),
            TMZButton(
              label: 'Reject',
              variant: TMZButtonVariant.dangerGhost,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
