import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/models/verification_models.dart';
import '../../../../../core/router/app_router.dart';
import 'org_verification_completion_view.dart';

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

    return OrgVerificationCompletionView(
      headerTitle: 'Verification Submitted',
      title: 'Verification Submitted',
      subtitle:
          'Your product verification batch has been queued. Review is now pending.',
      subjectName: (qp['batch'] ?? 'New Product Batch').trim(),
      subjectIdLabel: 'Batch ID',
      subjectIdValue: batchId,
      metrics: <OrgCompletionMetric>[
        OrgCompletionMetric(label: 'Products', value: records.toString()),
        OrgCompletionMetric(label: 'Skipped', value: skipped.toString()),
        OrgCompletionMetric(
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
