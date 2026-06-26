import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../orgs/verification_flow/presentation/pages/org_verification_completion_view.dart';

class IndividualSkillTreeCompletionPage extends StatelessWidget {
  const IndividualSkillTreeCompletionPage({super.key});

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
    final int uploaded = _tryParseInt(qp['submitted'], fallback: 0);
    final int skipped = _tryParseInt(qp['skipped'], fallback: 0);
    final int errors = _tryParseInt(qp['errors'], fallback: 0);
    final String subjectName = (qp['subject'] ?? 'Skill Tree').trim();
    final String subjectId = (qp['submission_id'] ?? '').trim();

    return OrgVerificationCompletionView(
      headerTitle: 'Verification Submitted',
      title: 'Verification Submitted',
      subtitle:
          'Your skill tree was received. The review is now pending.',
      subjectName: subjectName,
      subjectIdLabel: 'Submission ID',
      subjectIdValue: subjectId.isEmpty ? '—' : subjectId,
      metrics: <OrgCompletionMetric>[
        OrgCompletionMetric(label: 'Uploaded', value: uploaded.toString()),
        OrgCompletionMetric(label: 'Skipped', value: skipped.toString()),
        OrgCompletionMetric(label: 'Errors', value: errors.toString()),
      ],
      primaryActionLabel: 'Dashboard',
      primaryAction: () => context.go(AppRouter.individualIdentityPath),
      secondaryActionLabel: 'Skill Tree',
      secondaryAction: () => context.go(AppRouter.individualScanPath),
    );
  }
}
