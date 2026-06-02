import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/router/app_router.dart';
import 'batch_created_success_view.dart';

class ProductBatchCreatedPage extends StatelessWidget {
  const ProductBatchCreatedPage({super.key});

  static int _tryParseInt(String? value, {required int fallback}) {
    if (value == null) return fallback;
    final int? parsed = int.tryParse(value);
    return parsed ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> qp = GoRouterState.of(
      context,
    ).uri.queryParameters;

    final int records = _tryParseInt(qp['records'], fallback: 0);
    final int skipped = _tryParseInt(qp['skipped'], fallback: 0);
    final String batchId = (qp['batchId'] ?? '').trim();
    final Object? extra = GoRouterState.of(context).extra;
    final BulkUploadResponse? report = extra is BulkUploadResponse
        ? extra
        : null;

    return BatchCreatedSuccessView(
      heroAssetPath: 'assets/batch_created_Success.svg',
      title: 'Batch Created!',
      subtitle:
          'Your product verification batch has been queued. Certificates will be generated and stored on blockchain.',
      batchName: (qp['batch'] ?? 'New Product Batch').trim(),
      batchIdLabel: 'Batch ID',
      batchIdValue: batchId,
      metrics: <BatchCreatedMetric>[
        BatchCreatedMetric(label: 'Products', value: records.toString()),
        BatchCreatedMetric(label: 'Skipped', value: skipped.toString()),
        BatchCreatedMetric(
          label: 'Errors',
          value: (report?.errors.length ?? 0).toString(),
        ),
      ],
      primaryActionLabel: 'View Batch',
      primaryAction: batchId.trim().isEmpty
          ? () => context.go(AppRouter.appBatchesPath)
          : () => context.go(
              '${AppRouter.appBatchTrackingDetailPath}?batch_id=${Uri.encodeQueryComponent(batchId)}',
            ),
      secondaryActionLabel: 'Dashboard',
      secondaryAction: () => context.go(AppRouter.dashboardPath),
    );
  }
}
