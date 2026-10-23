import 'package:flutter_test/flutter_test.dart';

import 'package:trumarkz/core/models/auth_models.dart';
import 'package:trumarkz/core/models/notification_models.dart';
import 'package:trumarkz/core/models/org_permission.dart';
import 'package:trumarkz/core/models/verification_models.dart';

void main() {
  group('OrgPermissionMode', () {
    test('parses the canonical wire values', () {
      expect(
        OrgPermissionMode.fromWire('open_search'),
        OrgPermissionMode.openSearch,
      );
      expect(
        OrgPermissionMode.fromWire('permission_required'),
        OrgPermissionMode.permissionRequired,
      );
    });

    test('parses the public/private aliases', () {
      expect(
        OrgPermissionMode.fromWire('public'),
        OrgPermissionMode.openSearch,
      );
      expect(
        OrgPermissionMode.fromWire('private'),
        OrgPermissionMode.permissionRequired,
      );
    });

    test('treats an unknown or empty value as open search', () {
      expect(OrgPermissionMode.fromWire(null), isNull);
      expect(OrgPermissionMode.fromWire(''), isNull);
      expect(OrgPermissionMode.fromWire('nonsense'), isNull);
    });

    test('resolves the batch visibility over the organization default', () {
      expect(
        resolvePermissionMode(
          organizationDefault: OrgPermissionMode.permissionRequired,
          credentialVisibility: 'publicSearchable',
        ),
        OrgPermissionMode.openSearch,
      );
      expect(
        resolvePermissionMode(
          organizationDefault: OrgPermissionMode.openSearch,
          credentialVisibility: 'permissionBasedAccess',
        ),
        OrgPermissionMode.permissionRequired,
      );
    });

    test('falls back to the organization default when the batch has none', () {
      expect(
        resolvePermissionMode(
          organizationDefault: OrgPermissionMode.permissionRequired,
        ),
        OrgPermissionMode.permissionRequired,
      );
      expect(
        resolvePermissionMode(organizationDefault: null),
        OrgPermissionMode.openSearch,
      );
    });

    test('converts app navigation aliases to backend batch values', () {
      expect(canonicalCredentialVisibility('permissionBasedAccess'), 'private');
      expect(canonicalCredentialVisibility('publicSearchable'), 'public');
      expect(canonicalCredentialVisibility(null), isNull);
    });
  });

  group('UserProfile permission_mode', () {
    test('reads permission_mode from /auth/me', () {
      final UserProfile profile = UserProfile.fromJson(<String, dynamic>{
        'id': 'org-1',
        'email': 'ops@example.com',
        'permission_mode': 'permission_required',
      });
      expect(profile.permissionMode, OrgPermissionMode.permissionRequired);
      expect(
        profile.effectivePermissionMode,
        OrgPermissionMode.permissionRequired,
      );
    });

    test('treats a missing permission_mode as open search', () {
      final UserProfile profile = UserProfile.fromJson(<String, dynamic>{
        'id': 'org-1',
        'email': 'ops@example.com',
      });
      expect(profile.permissionMode, isNull);
      expect(profile.effectivePermissionMode, OrgPermissionMode.openSearch);
    });
  });

  group('VerificationUser consent fields', () {
    test('parses the consent state from /verification/all', () {
      final VerificationUser user = VerificationUser.fromJson(<String, dynamic>{
        'id': 'user-1',
        'consent_status': 'pending',
        'consent_deadline': '2026-10-22T10:00:00Z',
        'consent_auto_expired': false,
      });
      expect(user.hasConsentStatus, isTrue);
      expect(user.isConsentPending, isTrue);
      expect(user.consentDeadlineAt, isNotNull);
      expect(user.consentStatusLabel, 'Awaiting consent');
    });

    test('leaves consent empty for product and open-search records', () {
      final VerificationUser user = VerificationUser.fromJson(<String, dynamic>{
        'id': 'user-1',
      });
      expect(user.hasConsentStatus, isFalse);
      expect(user.isConsentPending, isFalse);
      expect(user.consentStatusLabel, '');
    });

    test(
      'distinguishes an auto-expired rejection from an explicit decline',
      () {
        final VerificationUser expired =
            VerificationUser.fromJson(<String, dynamic>{
              'id': 'user-1',
              'consent_status': 'rejected',
              'consent_auto_expired': true,
            });
        final VerificationUser declined =
            VerificationUser.fromJson(<String, dynamic>{
              'id': 'user-2',
              'consent_status': 'rejected',
              'consent_auto_expired': false,
            });
        expect(expired.consentStatusLabel, 'Consent expired');
        expect(declined.consentStatusLabel, 'Consent declined');
      },
    );
  });

  group('OrgNotification', () {
    test('parses a batch_deleted notification', () {
      final OrgNotification notification =
          OrgNotification.fromJson(<String, dynamic>{
            'id': 'n-1',
            'notification_type': 'batch_deleted',
            'message': "Batch 'Q1' was deleted by the superadmin.",
            'batch_id': 'batch-1',
            'is_read': false,
            'created_at': '2026-10-22T10:00:00Z',
          });
      expect(notification.id, 'n-1');
      expect(notification.isBatchDeleted, isTrue);
      expect(notification.isUnread, isTrue);
      expect(notification.batchId, 'batch-1');
      expect(notification.createdAtDateTime, isNotNull);
    });

    test('keeps a null batch id as null', () {
      final OrgNotification notification =
          OrgNotification.fromJson(<String, dynamic>{
            'id': 'n-1',
            'notification_type': 'batch_deleted',
            'message': 'Something happened.',
            'batch_id': null,
            'is_read': true,
            'created_at': '2026-10-22T10:00:00Z',
          });
      expect(notification.batchId, isNull);
      expect(notification.isRead, isTrue);
    });
  });
}
