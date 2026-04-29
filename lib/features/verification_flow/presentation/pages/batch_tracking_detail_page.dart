import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/tmz_badge.dart';
import '../../../../core/widgets/tmz_card.dart';

class BatchTrackingDetailPage extends StatelessWidget {
  const BatchTrackingDetailPage({super.key});

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
            const Text('Batch Tracking'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x4),
        children: <Widget>[
          Text('Batch #A1C3', style: AppTypography.display2),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Progress • 24/80 complete',
            style: AppTypography.body2.copyWith(color: scheme.onSurface.withAlpha(160)),
          ),
          const SizedBox(height: AppSpacing.x4),
          TMZCard(
            onTap: () => context.push(AppRouter.individualRecordDetailPath),
            child: const ListTile(
              leading: Icon(Icons.person_outline_rounded),
              title: Text('John Doe'),
              subtitle: Text('Verified'),
              trailing: TMZBadge(
                label: 'Verified',
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          TMZCard(
            onTap: () => context.push(AppRouter.individualRecordDetailPath),
            child: const ListTile(
              leading: Icon(Icons.person_outline_rounded),
              title: Text('Jane Smith'),
              subtitle: Text('Pending'),
              trailing: TMZBadge(
                label: 'Pending',
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

