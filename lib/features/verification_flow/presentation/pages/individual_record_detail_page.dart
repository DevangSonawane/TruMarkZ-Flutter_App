import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/tmz_card.dart';

class IndividualRecordDetailPage extends StatelessWidget {
  const IndividualRecordDetailPage({super.key});

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
            const Text('Record Detail'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: const <Widget>[
          TMZCard(
            child: ListTile(
              leading: Icon(Icons.person_outline_rounded),
              title: Text('John Doe'),
              subtitle: Text('National ID • Verified'),
            ),
          ),
          SizedBox(height: AppSpacing.x3),
          TMZCard(
            child: ListTile(
              leading: Icon(Icons.link_rounded),
              title: Text('On-chain Proof'),
              subtitle: Text('Tx: 0x9f3a...c812'),
            ),
          ),
          SizedBox(height: AppSpacing.x3),
          TMZCard(
            child: ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text('Document Snapshot'),
              subtitle: Text('ID front/back validated'),
            ),
          ),
        ],
      ),
    );
  }
}
