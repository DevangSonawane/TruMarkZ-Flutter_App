import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_card.dart';

class SuperAdminDashboardPage extends StatelessWidget {
  const SuperAdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 22),
            const SizedBox(width: AppSpacing.x2),
            const Text('Super Admin'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.go(AppRouter.settingsPath),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Dashboard', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x3),
          TMZCard(
            onTap: () => context.go(AppRouter.organisationApprovalDetailPath),
            child: const ListTile(
              leading: Icon(Icons.approval_rounded),
              title: Text('Organisation awaiting approval'),
              subtitle: Text('3 pending'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          TMZCard(
            onTap: () => context.go(AppRouter.batchMonitoringDetailPath),
            child: const ListTile(
              leading: Icon(Icons.monitor_heart_outlined),
              title: Text('Batch monitoring'),
              subtitle: Text('View live verification batches'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
