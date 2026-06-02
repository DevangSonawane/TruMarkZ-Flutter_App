import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import 'batch_created_success_view.dart';

class BatchCreatedSuccessPage extends StatelessWidget {
  const BatchCreatedSuccessPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final int? parsed = int.tryParse(value);
    return parsed ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(context).uri.queryParameters;
    final String batchId = (qp['batch_id'] ?? '').trim();
    final int uploaded = _tryParseInt(qp['total_uploaded'], fallback: 0);
    final int skipped = _tryParseInt(qp['total_skipped'], fallback: 0);
    final int errors = _tryParseInt(qp['errors'], fallback: 0);
    final String batchName = (qp['batch'] ?? 'New Batch').trim();

    return BatchCreatedSuccessView(
      heroAssetPath: 'assets/batch_created_Success.svg',
      title: 'Batch Created!',
      subtitle:
          'Your bulk upload was received. Verification tasks will be created shortly.',
      batchName: batchName,
      batchIdLabel: 'Batch ID',
      batchIdValue: batchId,
      metrics: <BatchCreatedMetric>[
        BatchCreatedMetric(label: 'Uploaded', value: uploaded.toString()),
        BatchCreatedMetric(label: 'Skipped', value: skipped.toString()),
        BatchCreatedMetric(label: 'Errors', value: errors.toString()),
      ],
      banners: <BatchCreatedBanner>[
        if (skipped > 0)
          BatchCreatedBanner(
            title: '$skipped records were skipped',
            subtitle:
                'Check your Excel file for missing required fields (full_name, email, phone_number).',
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFFFBEB),
            icon: Icons.warning_amber_rounded,
          ),
        if (errors > 0)
          BatchCreatedBanner(
            title: '$errors rows had errors',
            subtitle:
                'Please fix the invalid rows and upload again to include them in this batch.',
            color: const Color(0xFFEF4444),
            bg: const Color(0xFFFEF2F2),
            icon: Icons.error_outline_rounded,
          ),
      ],
      primaryActionLabel: 'View Batch',
      primaryAction: batchId.trim().isEmpty
          ? () => context.go(AppRouter.appBatchesPath)
          : () => context.go(
              '${AppRouter.appBatchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(batchId)}',
            ),
      secondaryActionLabel: 'Back to Dashboard',
      secondaryAction: () => context.go(AppRouter.dashboardPath),
    );
  }
}
