import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/notifications/presentation/pages/notification_centre_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/progress/presentation/pages/batch_progress_page.dart';
import '../../features/verification_flow/presentation/pages/batch_tracking_detail_page.dart';
import '../../features/verification_flow/presentation/pages/batch_job_running_page.dart';
import '../../features/verification_flow/presentation/pages/bulk_upload_page.dart';
import '../../features/registry/presentation/pages/registry_search_page.dart';
import '../../features/registry/presentation/pages/public_verification_result_page.dart';
import '../../features/settings/presentation/pages/profile_settings_page.dart';
import '../../features/shell/presentation/pages/org_shell_page.dart';
import '../../features/skills/presentation/pages/skill_tree_page.dart';
import '../../features/verification/presentation/pages/qr_scanner_page.dart';
import '../../features/verification_flow/presentation/pages/credential_detail_page.dart';
import '../../features/verification_flow/presentation/pages/credential_template_selector_page.dart';
import '../../features/verification_flow/presentation/pages/credentials_generated_page.dart';
import '../../features/verification_flow/presentation/pages/individual_record_detail_page.dart';
import '../../features/verification_flow/presentation/pages/map_credential_fields_page.dart';
import '../../features/verification_flow/presentation/pages/otp_verification_page.dart';
import '../../features/verification_flow/presentation/pages/organisation_registration_page.dart';
import '../../features/verification_flow/presentation/pages/pending_approval_page.dart';
import '../../features/verification_flow/presentation/pages/verification_plan_setup_page.dart';
import '../../features/verification_plan/presentation/pages/verification_plan_builder_page.dart';
import '../../features/wallet/presentation/pages/credential_wallet_page.dart';
import '../../features/admin/presentation/pages/super_admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/organisation_approval_detail_page.dart';
import '../../features/admin/presentation/pages/batch_monitoring_detail_page.dart';

class AppRouter {
  static const String splashPath = '/';
  static const String onboardingPath = '/onboarding';
  static const String roleSelectionPath = '/role-selection';
  static const String loginPath = '/login';
  static const String registerPath = '/register';

  static const String dashboardPath = '/app/dashboard';
  static const String walletPath = '/app/wallet';
  static const String qrScannerPath = '/app/qr-scan';
  static const String appBatchesPath = '/app/batches';
  static const String appBatchTrackingDetailPath = '/app/batches/tracking';
  static const String appIndividualRecordDetailPath = '/app/batches/record';
  static const String appCredentialDetailPath = '/app/batches/credential';
  static const String appRegistryPath = '/app/registry';
  static const String settingsPath = '/app/settings';

  static const String notificationsPath = '/notifications';

  static const String verificationPlanBuilderPath =
      '/verification-plan-builder';
  static const String registrySearchPath = '/registry-search';
  static const String skillTreePath = '/skill-tree';
  static const String batchProgressPath = '/batch-progress';

  // Organisation auth flow
  static const String organisationRegistrationPath = '/org-registration';
  static const String otpVerificationPath = '/otp-verification';
  static const String pendingApprovalPath = '/pending-approval';

  // Organisation bulk verification flow
  static const String verificationPlanSetupPath = '/verification-plan-setup';
  static const String credentialTemplateSelectorPath =
      '/credential-template-selector';
  static const String mapCredentialFieldsPath = '/map-credential-fields';
  static const String batchJobRunningPath = '/batch-job-running';
  static const String bulkUploadPath = '/bulk-upload';
  static const String credentialsGeneratedPath = '/credentials-generated';
  static const String batchTrackingDetailPath = '/batch-tracking-detail';
  static const String individualRecordDetailPath = '/record-detail';
  static const String credentialDetailPath = '/credential-detail';

  // Public verification
  static const String publicVerificationResultPath =
      '/public-verification-result';

  // Admin
  static const String superAdminDashboardPath = '/admin/dashboard';
  static const String organisationApprovalDetailPath = '/admin/org-approval';
  static const String batchMonitoringDetailPath = '/admin/batch-monitoring';

  static final GoRouter router = GoRouter(
    initialLocation: splashPath,
    routes: <RouteBase>[
      GoRoute(
        path: splashPath,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashPage(),
      ),
      GoRoute(
        path: onboardingPath,
        name: 'onboarding',
        builder: (BuildContext context, GoRouterState state) =>
            const OnboardingPage(),
      ),
      GoRoute(
        path: roleSelectionPath,
        name: 'role_selection',
        builder: (BuildContext context, GoRouterState state) =>
            const RoleSelectionPage(),
      ),
      GoRoute(
        path: loginPath,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),
      GoRoute(
        path: registerPath,
        name: 'register',
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterPage(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            OrgShellPage(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: dashboardPath,
            name: 'dashboard',
            builder: (BuildContext context, GoRouterState state) =>
                const DashboardPage(),
          ),
          GoRoute(
            path: appBatchesPath,
            name: 'batches',
            builder: (BuildContext context, GoRouterState state) =>
                const BatchProgressPage(),
          ),
          GoRoute(
            path: appBatchTrackingDetailPath,
            name: 'app_batch_tracking_detail',
            builder: (BuildContext context, GoRouterState state) =>
                const BatchTrackingDetailPage(),
          ),
          GoRoute(
            path: appIndividualRecordDetailPath,
            name: 'app_record_detail',
            builder: (BuildContext context, GoRouterState state) =>
                const IndividualRecordDetailPage(),
          ),
          GoRoute(
            path: appCredentialDetailPath,
            name: 'app_credential_detail',
            builder: (BuildContext context, GoRouterState state) =>
                const CredentialDetailPage(),
          ),
          GoRoute(
            path: appRegistryPath,
            name: 'registry',
            builder: (BuildContext context, GoRouterState state) =>
                const RegistrySearchPage(),
          ),
          GoRoute(
            path: walletPath,
            name: 'wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const CredentialWalletPage(),
          ),
          GoRoute(
            path: qrScannerPath,
            name: 'qr_scan',
            builder: (BuildContext context, GoRouterState state) =>
                const QRScannerPage(),
          ),
          GoRoute(
            path: settingsPath,
            name: 'settings',
            builder: (BuildContext context, GoRouterState state) =>
                const ProfileSettingsPage(),
          ),
        ],
      ),
      GoRoute(
        path: notificationsPath,
        name: 'notifications',
        builder: (BuildContext context, GoRouterState state) =>
            const NotificationCentrePage(),
      ),
      GoRoute(
        path: verificationPlanBuilderPath,
        name: 'verification_plan_builder',
        builder: (BuildContext context, GoRouterState state) =>
            const VerificationPlanBuilderPage(),
      ),
      GoRoute(
        path: registrySearchPath,
        name: 'registry_search',
        redirect: (BuildContext context, GoRouterState state) {
          final String query = state.uri.hasQuery ? '?${state.uri.query}' : '';
          return '$appRegistryPath$query';
        },
      ),
      GoRoute(
        path: publicVerificationResultPath,
        name: 'public_verification_result',
        builder: (BuildContext context, GoRouterState state) =>
            const PublicVerificationResultPage(),
      ),
      GoRoute(
        path: skillTreePath,
        name: 'skill_tree',
        builder: (BuildContext context, GoRouterState state) =>
            const SkillTreePage(),
      ),
      GoRoute(
        path: batchProgressPath,
        name: 'batch_progress',
        redirect: (BuildContext context, GoRouterState state) {
          final String query = state.uri.hasQuery ? '?${state.uri.query}' : '';
          return '$appBatchesPath$query';
        },
      ),

      // Organisation auth flow
      GoRoute(
        path: organisationRegistrationPath,
        name: 'org_registration',
        builder: (BuildContext context, GoRouterState state) =>
            const OrganisationRegistrationPage(),
      ),
      GoRoute(
        path: otpVerificationPath,
        name: 'otp_verification',
        builder: (BuildContext context, GoRouterState state) =>
            const OtpVerificationPage(),
      ),
      GoRoute(
        path: pendingApprovalPath,
        name: 'pending_approval',
        builder: (BuildContext context, GoRouterState state) =>
            const PendingApprovalPage(),
      ),

      // Organisation bulk verification flow
      GoRoute(
        path: verificationPlanSetupPath,
        name: 'verification_plan_setup',
        builder: (BuildContext context, GoRouterState state) =>
            const VerificationPlanSetupPage(),
      ),
      GoRoute(
        path: credentialTemplateSelectorPath,
        name: 'credential_template_selector',
        builder: (BuildContext context, GoRouterState state) =>
            const CredentialTemplateSelectorPage(),
      ),
      GoRoute(
        path: mapCredentialFieldsPath,
        name: 'map_credential_fields',
        builder: (BuildContext context, GoRouterState state) =>
            const MapCredentialFieldsPage(),
      ),
      GoRoute(
        path: batchJobRunningPath,
        name: 'batch_job_running',
        builder: (BuildContext context, GoRouterState state) =>
            const BatchJobRunningPage(),
      ),
      GoRoute(
        path: bulkUploadPath,
        name: 'bulk_upload',
        builder: (BuildContext context, GoRouterState state) =>
            const BulkUploadPage(),
      ),
      GoRoute(
        path: credentialsGeneratedPath,
        name: 'credentials_generated',
        builder: (BuildContext context, GoRouterState state) =>
            const CredentialsGeneratedPage(),
      ),
      GoRoute(
        path: batchTrackingDetailPath,
        name: 'batch_tracking_detail',
        builder: (BuildContext context, GoRouterState state) =>
            const BatchTrackingDetailPage(),
      ),
      GoRoute(
        path: individualRecordDetailPath,
        name: 'individual_record_detail',
        builder: (BuildContext context, GoRouterState state) =>
            const IndividualRecordDetailPage(),
      ),
      GoRoute(
        path: credentialDetailPath,
        name: 'credential_detail',
        builder: (BuildContext context, GoRouterState state) =>
            const CredentialDetailPage(),
      ),

      // Admin
      GoRoute(
        path: superAdminDashboardPath,
        name: 'admin_dashboard',
        builder: (BuildContext context, GoRouterState state) =>
            const SuperAdminDashboardPage(),
      ),
      GoRoute(
        path: organisationApprovalDetailPath,
        name: 'org_approval_detail',
        builder: (BuildContext context, GoRouterState state) =>
            const OrganisationApprovalDetailPage(),
      ),
      GoRoute(
        path: batchMonitoringDetailPath,
        name: 'batch_monitoring_detail',
        builder: (BuildContext context, GoRouterState state) =>
            const BatchMonitoringDetailPage(),
      ),
    ],
  );
}
