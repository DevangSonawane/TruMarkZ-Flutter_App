import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/tmz_card.dart';

class BatchMonitoringDetailPage extends StatelessWidget {
  const BatchMonitoringDetailPage({super.key});

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
