import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/tmz_card.dart';

class BatchMonitoringDetailPage extends StatelessWidget {
  const BatchMonitoringDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Image.asset('assets/icons/headers_app_icon.png', height: 22),
            const SizedBox(width: AppSpacing.x2),
            const Text('Batch Monitoring'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: const <Widget>[
          TMZCard(
            child: ListTile(
              leading: Icon(Icons.timelapse_rounded),
              title: Text('Batch #A1C3'),
              subtitle: Text('In progress • 24/80 complete'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
          SizedBox(height: AppSpacing.x3),
          TMZCard(
            child: ListTile(
              leading: Icon(Icons.timelapse_rounded),
              title: Text('Batch #B2D9'),
              subtitle: Text('Completed • 120/120'),
              trailing: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
