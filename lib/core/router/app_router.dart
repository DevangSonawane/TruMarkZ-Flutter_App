import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/role_selection_page.dart';
import '../../features/individual/presentation/pages/individual_dashboard_page.dart';
import '../../features/individual/presentation/pages/individual_profile_page.dart';
import '../../features/individual/presentation/pages/individual_skill_tree_page.dart';
import '../../features/individual/presentation/pages/individual_vault_page.dart';
import '../../features/individual/presentation/shell/app_shell_page.dart';
import '../../features/notifications/presentation/pages/notification_centre_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/orgs/presentation/pages/batch_progress_page.dart';
import '../../features/orgs/presentation/pages/org_credentials_page.dart';
import '../../features/orgs/presentation/pages/org_dashboard_page.dart';
import '../../features/orgs/presentation/pages/profile_settings_page.dart';
import '../../features/orgs/presentation/pages/registry_search_page.dart';
import '../../features/orgs/presentation/pages/verification_plan_builder_page.dart';
import '../../features/orgs/presentation/pages/verification_report_detail_page.dart';
import '../../features/orgs/presentation/pages/verification_reports_page.dart';
import '../../features/orgs/presentation/shell/org_shell_page.dart';
import '../../features/skills/presentation/pages/skill_tree_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/batch_job_running_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/batch_tracking_detail_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/batch_created_success_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/bulk_upload_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/credential_detail_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/credential_template_selector_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/credential_preview_approval_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/credentials_approved_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/credentials_generated_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/individual_record_detail_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/map_credential_fields_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/organisation_registration_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/otp_verification_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/pending_approval_page.dart';
import '../../features/orgs/verification_flow/presentation/pages/verification_plan_setup_page.dart';
import '../../features/scanner/presentation/pages/qr_scanner_page.dart';
import '../../features/just_verifying/presentation/pages/public_verification_result_page.dart';
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
  static const String appReportsPath = '/app/reports';
  static const String appReportDetailPath = '/app/reports/detail';

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
  static const String credentialPreviewApprovalPath =
      '/credential-preview-approval';
  static const String credentialsApprovedPath = '/credentials-approved';
  static const String batchJobRunningPath = '/batch-job-running';
  static const String bulkUploadPath = '/bulk-upload';
  static const String batchCreatedSuccessPath = '/batch-created-success';
  static const String credentialsGeneratedPath = '/credentials-generated';
  static const String batchTrackingDetailPath = '/batch-tracking-detail';
  static const String individualRecordDetailPath = '/record-detail';
  static const String credentialDetailPath = '/credential-detail';

  // Public verification
  static const String publicVerificationResultPath =
      '/public-verification-result';

  // Individual
  static const String individualIdentityPath = '/me/identity';
  static const String individualScanPath = '/me/scan';
  static const String individualVaultPath = '/me/vault';
  static const String individualProfilePath = '/me/profile';

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
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const SplashPage()),
      ),
      GoRoute(
        path: onboardingPath,
        name: 'onboarding',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const OnboardingPage()),
      ),
      GoRoute(
        path: roleSelectionPath,
        name: 'role_selection',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const RoleSelectionPage()),
      ),
      GoRoute(
        path: loginPath,
        name: 'login',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const LoginPage()),
      ),
      GoRoute(
        path: registerPath,
        name: 'register',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const RegisterPage()),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            OrgShellPage(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: dashboardPath,
            name: 'dashboard',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(state: state, child: const OrgDashboardPage()),
          ),
          GoRoute(
            path: appBatchesPath,
            name: 'batches',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(state: state, child: const BatchProgressPage()),
          ),
          GoRoute(
            path: appBatchTrackingDetailPath,
            name: 'app_batch_tracking_detail',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const BatchTrackingDetailPage(),
                ),
          ),
          GoRoute(
            path: appIndividualRecordDetailPath,
            name: 'app_record_detail',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const IndividualRecordDetailPage(),
                ),
          ),
          GoRoute(
            path: appCredentialDetailPath,
            name: 'app_credential_detail',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const CredentialDetailPage(),
                ),
          ),
          GoRoute(
            path: appRegistryPath,
            name: 'registry',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(state: state, child: const RegistrySearchPage()),
          ),
          GoRoute(
            path: walletPath,
            name: 'wallet',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(state: state, child: const OrgCredentialsPage()),
          ),
          GoRoute(
            path: qrScannerPath,
            name: 'qr_scan',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(state: state, child: const QRScannerPage()),
          ),
          GoRoute(
            path: settingsPath,
            name: 'settings',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const ProfileSettingsPage(),
                ),
          ),
          GoRoute(
            path: appReportsPath,
            name: 'app_reports',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const VerificationReportsPage(),
                ),
          ),
          GoRoute(
            path: appReportDetailPath,
            name: 'app_report_detail',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const VerificationReportDetailPage(),
                ),
          ),
        ],
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            IndividualShellPage(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: individualIdentityPath,
            name: 'individual_identity',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const IndividualDashboardPage(),
                ),
          ),
          GoRoute(
            path: individualScanPath,
            name: 'individual_scan',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const IndividualSkillTreePage(),
                ),
          ),
          GoRoute(
            path: individualVaultPath,
            name: 'individual_vault',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const IndividualVaultPage(),
                ),
          ),
          GoRoute(
            path: individualProfilePath,
            name: 'individual_profile',
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _slideFadePage(
                  state: state,
                  child: const IndividualProfilePage(),
                ),
          ),
        ],
      ),
      GoRoute(
        path: notificationsPath,
        name: 'notifications',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const NotificationCentrePage()),
      ),
      GoRoute(
        path: verificationPlanBuilderPath,
        name: 'verification_plan_builder',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const VerificationPlanBuilderPage(),
            ),
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
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const PublicVerificationResultPage(),
            ),
      ),
      GoRoute(
        path: skillTreePath,
        name: 'skill_tree',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const SkillTreePage()),
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
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const OrganisationRegistrationPage(),
            ),
      ),
      GoRoute(
        path: otpVerificationPath,
        name: 'otp_verification',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const OtpVerificationPage()),
      ),
      GoRoute(
        path: pendingApprovalPath,
        name: 'pending_approval',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const PendingApprovalPage()),
      ),

      // Organisation bulk verification flow
      GoRoute(
        path: verificationPlanSetupPath,
        name: 'verification_plan_setup',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const VerificationPlanSetupPage(),
            ),
      ),
      GoRoute(
        path: credentialTemplateSelectorPath,
        name: 'credential_template_selector',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const CredentialTemplateSelectorPage(),
            ),
      ),
      GoRoute(
        path: mapCredentialFieldsPath,
        name: 'map_credential_fields',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const MapCredentialFieldsPage(),
            ),
      ),
      GoRoute(
        path: credentialPreviewApprovalPath,
        name: 'credential_preview_approval',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const CredentialPreviewApprovalPage(),
            ),
      ),
      GoRoute(
        path: credentialsApprovedPath,
        name: 'credentials_approved',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const CredentialsApprovedPage(),
            ),
      ),
      GoRoute(
        path: batchJobRunningPath,
        name: 'batch_job_running',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const BatchJobRunningPage()),
      ),
      GoRoute(
        path: bulkUploadPath,
        name: 'bulk_upload',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const BulkUploadPage()),
      ),
      GoRoute(
        path: batchCreatedSuccessPath,
        name: 'batch_created_success',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const BatchCreatedSuccessPage(),
            ),
      ),
      GoRoute(
        path: credentialsGeneratedPath,
        name: 'credentials_generated',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const CredentialsGeneratedPage(),
            ),
      ),
      GoRoute(
        path: batchTrackingDetailPath,
        name: 'batch_tracking_detail',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const BatchTrackingDetailPage(),
            ),
      ),
      GoRoute(
        path: individualRecordDetailPath,
        name: 'individual_record_detail',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const IndividualRecordDetailPage(),
            ),
      ),
      GoRoute(
        path: credentialDetailPath,
        name: 'credential_detail',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(state: state, child: const CredentialDetailPage()),
      ),

      // Admin
      GoRoute(
        path: superAdminDashboardPath,
        name: 'admin_dashboard',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const SuperAdminDashboardPage(),
            ),
      ),
      GoRoute(
        path: organisationApprovalDetailPath,
        name: 'org_approval_detail',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const OrganisationApprovalDetailPage(),
            ),
      ),
      GoRoute(
        path: batchMonitoringDetailPath,
        name: 'batch_monitoring_detail',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _slideFadePage(
              state: state,
              child: const BatchMonitoringDetailPage(),
            ),
      ),
    ],
  );

  static CustomTransitionPage<void> _slideFadePage({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<Offset> slideAnim =
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
            final Animation<double> fadeAnim =
                Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                );
            return FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(position: slideAnim, child: child),
            );
          },
    );
  }
}
