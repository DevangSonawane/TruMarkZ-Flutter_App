import 'org_permission.dart';

/// Deprecated read-only compatibility model. New schema selection is handled
/// exclusively by organization Custom Schemas.
class DhiwayDetail {
  const DhiwayDetail({
    required this.spaceId,
    required this.schemaId,
    this.isDefault,
  });

  final String spaceId;
  final String schemaId;
  final bool? isDefault;
}

class LoginRequest {
  const LoginRequest({
    required this.loginType,
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  final String loginType;
  final String email;
  final String password;
  final bool rememberMe;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'password': password,
  };
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.loginType,
    required this.requiresOnboarding,
  });

  final String accessToken;
  final String tokenType;
  final String userId;
  final String loginType;
  final bool requiresOnboarding;

  factory LoginResponse.fromJson(
    Map<String, dynamic> json, {
    String fallbackLoginType = '',
  }) {
    final String inferredType =
        (json['login_type'] ?? json['user_type'] ?? fallbackLoginType)
            .toString();
    return LoginResponse(
      accessToken: (json['access_token'] ?? '').toString(),
      tokenType: (json['token_type'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      loginType: inferredType,
      requiresOnboarding: json['requires_onboarding'] == true,
    );
  }
}

class RegisterIndividualRequest {
  const RegisterIndividualRequest({
    required this.fullName,
    required this.email,
    this.mobile,
    this.address,
    required this.password,
  });

  final String fullName;
  final String email;
  final String? mobile;
  final String? address;
  final String password;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'password': password,
    };
    if (mobile != null && mobile!.trim().isNotEmpty) {
      json['phone_number'] = mobile!.trim();
    }
    if (address != null && address!.trim().isNotEmpty) {
      json['address'] = address;
    }
    return json;
  }
}

class SignupOrganizationRequest {
  const SignupOrganizationRequest({
    this.orgName,
    required this.email,
    this.phoneNumber,
    required this.password,
    this.serviceType,
  });

  final String? orgName;
  final String email;
  final String? phoneNumber;
  final String password;
  final String? serviceType;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'email': email,
      'password': password,
    };

    void putIfNonEmpty(String key, String? value) {
      final String normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        json[key] = normalized;
      }
    }

    putIfNonEmpty('org_name', orgName);
    putIfNonEmpty('phone_number', phoneNumber);
    putIfNonEmpty('service_type', serviceType);

    return json;
  }
}

class OtpVerifyRequest {
  const OtpVerifyRequest({required this.email, required this.otpCode});

  final String email;
  final String otpCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'otp_code': otpCode,
  };
}

class ResendOtpRequest {
  const ResendOtpRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{'email': email};
}

class OrgOnboardingRequest {
  const OrgOnboardingRequest({
    this.gstin,
    this.businessRegNumber,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.industryType,
    this.useCases,
  });

  final String? gstin;
  final String? businessRegNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? industryType;
  final Map<String, dynamic>? useCases;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    String normalize(String? value) => value?.trim() ?? '';

    void putIfNonEmpty(String key, String? value) {
      final String normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        json[key] = normalized;
      }
    }

    putIfNonEmpty('gstin', normalize(gstin));
    putIfNonEmpty('business_reg_number', normalize(businessRegNumber));
    putIfNonEmpty('address_line1', normalize(addressLine1));
    putIfNonEmpty('address_line2', normalize(addressLine2));
    putIfNonEmpty('address_line3', normalize(addressLine3));
    putIfNonEmpty('industry_type', normalize(industryType));
    if (useCases != null && useCases!.isNotEmpty) {
      json['use_cases'] = useCases;
    }

    return json;
  }
}

class VerifyGstResponse {
  const VerifyGstResponse({
    required this.gstVerified,
    required this.gstin,
    required this.organizationName,
    required this.legalName,
    required this.tradeName,
    required this.gstStatus,
    required this.matchedOn,
    required this.message,
  });

  final bool gstVerified;
  final String gstin;
  final String organizationName;
  final String legalName;
  final String tradeName;
  final String gstStatus;
  final String matchedOn;
  final String message;

  factory VerifyGstResponse.fromJson(Map<String, dynamic> json) {
    return VerifyGstResponse(
      gstVerified: json['gst_verified'] == true,
      gstin: (json['gstin'] ?? '').toString(),
      organizationName: (json['organization_name'] ?? json['org_name'] ?? '')
          .toString(),
      legalName: (json['legal_name'] ?? '').toString(),
      tradeName: (json['trade_name'] ?? '').toString(),
      gstStatus: (json['gst_status'] ?? '').toString(),
      matchedOn: (json['matched_on'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class OrganizationProfileUpdateRequest {
  const OrganizationProfileUpdateRequest({
    this.organizationName,
    this.fullName,
    this.phoneNumber,
    this.gstin,
    this.businessRegNumber,
    this.addressLine1,
    this.addressLine2,
    this.addressLine3,
    this.serviceType,
    this.industryType,
    this.permissionMode,
  });

  final String? organizationName;
  final String? fullName;
  final String? phoneNumber;
  final String? gstin;
  final String? businessRegNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? serviceType;
  final String? industryType;

  /// Organization-level consent default for Human batches
  /// (new_flutter_trumarkz.md §12a). `null` leaves the stored value alone.
  final OrgPermissionMode? permissionMode;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void putIfNonEmpty(String key, String? value) {
      final String normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        json[key] = normalized;
      }
    }

    void putClearable(String key, String? value) {
      if (value == null) return;
      json[key] = value.trim();
    }

    putIfNonEmpty('org_name', organizationName);
    putClearable('full_name', fullName);
    putClearable('phone_number', phoneNumber);
    putClearable('gstin', gstin);
    putClearable('business_reg_number', businessRegNumber);
    putClearable('address_line1', addressLine1);
    putClearable('address_line2', addressLine2);
    putClearable('address_line3', addressLine3);
    putIfNonEmpty('service_type', serviceType);
    putIfNonEmpty('industry_type', industryType);
    if (permissionMode != null) {
      json['permission_mode'] = permissionMode!.wireValue;
    }
    return json;
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.userType,
    required this.loginType,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.organizationName,
    required this.industryTypes,
    required this.gstNumber,
    required this.businessRegistrationNumber,
    required this.industry,
    required this.address,
    required this.addressLine1,
    required this.addressLine2,
    required this.addressLine3,
    required this.serviceType,
    required this.useCases,
    required this.onboardingCompleted,
    required this.isActive,
    required this.isVerified,
    required this.gstVerified,
    required this.emailVerified,
    required this.mobileVerified,
    required this.skillTreeInitiated,
    required this.dhiwaysDetails,
    required this.storagePath,
    required this.createdAt,
    this.permissionMode,
  });

  final String id;
  final String userType;
  final String loginType;
  final String? fullName;
  final String email;
  final String? mobile;
  final String? organizationName;
  final List<String> industryTypes;
  final String? gstNumber;
  final String? businessRegistrationNumber;
  final String? industry;
  final String? address;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? serviceType;
  final Map<String, dynamic> useCases;
  final bool onboardingCompleted;
  final bool isActive;
  final bool isVerified;
  final bool gstVerified;
  final bool emailVerified;
  final bool mobileVerified;
  final bool skillTreeInitiated;
  final List<DhiwayDetail> dhiwaysDetails;
  final String storagePath;
  final DateTime? createdAt;

  /// Organization-level consent default for Human batches
  /// (new_flutter_trumarkz.md §12a). `null` means the backend has no
  /// explicit value set, which is equivalent to
  /// [OrgPermissionMode.openSearch].
  final OrgPermissionMode? permissionMode;

  /// Effective consent mode for this organization.
  OrgPermissionMode get effectivePermissionMode =>
      permissionMode ?? OrgPermissionMode.openSearch;

  String? get phoneNumber => mobile;
  String? get gstin => gstNumber;
  String? get businessRegNumber => businessRegistrationNumber;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final List<String> industryTypes = _readStringList(
      json['industry_type'] ?? json['industryTypes'],
    );
    final String? userType =
        _readStringOrNull(json['user_type']) ??
        _readStringOrNull(json['login_type']);
    final String loginType =
        _readStringOrNull(json['login_type']) ?? userType ?? '';
    final String? mobile = _readStringOrNull(
      json['phone_number'] ?? json['mobile'],
    );
    final String? organizationName = _readStringOrNull(
      json['org_name'] ?? json['organization_name'],
    );
    final String? gstNumber =
        _readStringOrNull(json['gstin']) ??
        _readStringOrNull(json['gst_number']);
    final String? businessRegistrationNumber =
        _readStringOrNull(json['business_reg_number']) ??
        _readStringOrNull(json['business_registration_number']);
    final String? addressLine1 = _readStringOrNull(json['address_line1']);
    final String? addressLine2 = _readStringOrNull(json['address_line2']);
    final String? addressLine3 = _readStringOrNull(json['address_line3']);
    final String? legacyAddress = _readStringOrNull(json['address']);
    final String? address = _joinNonEmpty(<String?>[
      addressLine1,
      addressLine2,
      addressLine3,
      legacyAddress,
    ]);
    final String? serviceType = _readStringOrNull(
      json['service_type'] ?? json['serviceType'],
    );
    final String? industry =
        _readStringOrNull(json['industry']) ??
        (industryTypes.isNotEmpty ? industryTypes.join(', ') : null);
    final Map<String, dynamic> useCases = _readStringMap(json['use_cases']);
    final DateTime? createdAt = DateTime.tryParse(
      (json['created_at'] ?? '').toString(),
    );
    final bool onboardingCompleted = json['onboarding_completed'] == true;
    final bool emailVerified = json['email_verified'] == true;
    final bool isVerified =
        json['is_verified'] == true || emailVerified || onboardingCompleted;
    final bool gstVerified =
        json['gst_verified'] == true || json['gstVerified'] == true;

    return UserProfile(
      id: (json['id'] ?? '').toString(),
      userType: userType ?? '',
      loginType: loginType,
      fullName: json['full_name']?.toString(),
      email: (json['email'] ?? '').toString(),
      mobile: mobile,
      organizationName: organizationName,
      industryTypes: industryTypes,
      gstNumber: gstNumber,
      businessRegistrationNumber: businessRegistrationNumber,
      industry: industry,
      address: address,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      addressLine3: addressLine3,
      serviceType: serviceType,
      useCases: useCases,
      onboardingCompleted: onboardingCompleted,
      isActive: json['is_active'] == true,
      isVerified: isVerified,
      gstVerified: gstVerified,
      emailVerified: emailVerified,
      mobileVerified: json['mobile_verified'] == true,
      skillTreeInitiated: json['skill_tree_initiated'] == true,
      dhiwaysDetails: const <DhiwayDetail>[],
      storagePath: (json['storage_path'] ?? '').toString(),
      createdAt: createdAt,
      permissionMode: OrgPermissionMode.fromWire(
        json['permission_mode'] ?? json['permissionMode'],
      ),
    );
  }
}

class AssignIndividualRequest {
  const AssignIndividualRequest({required this.individualEmailOrMobile});

  final String individualEmailOrMobile;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'individual_email_or_mobile': individualEmailOrMobile,
  };
}

class AssignIndividualResult {
  const AssignIndividualResult({
    required this.assignmentId,
    required this.storagePath,
  });

  final String assignmentId;
  final String storagePath;

  factory AssignIndividualResult.fromJson(Map<String, dynamic> json) {
    return AssignIndividualResult(
      assignmentId: (json['assignment_id'] ?? '').toString(),
      storagePath: (json['storage_path'] ?? '').toString(),
    );
  }
}

class InviteIndividualRequest {
  const InviteIndividualRequest({this.email, this.mobile});

  final String? email;
  final String? mobile;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'mobile': mobile,
  };
}

class InviteIndividualResult {
  const InviteIndividualResult({required this.inviteToken});

  final String inviteToken;

  factory InviteIndividualResult.fromJson(Map<String, dynamic> json) {
    return InviteIndividualResult(
      inviteToken: (json['invite_token'] ?? '').toString(),
    );
  }
}

class AssignedIndividual {
  const AssignedIndividual({
    required this.assignmentId,
    required this.individualId,
    required this.storagePath,
    required this.status,
    required this.assignedAt,
  });

  final String assignmentId;
  final String individualId;
  final String storagePath;
  final String status;
  final String assignedAt;

  factory AssignedIndividual.fromJson(Map<String, dynamic> json) {
    return AssignedIndividual(
      assignmentId: (json['assignment_id'] ?? '').toString(),
      individualId: (json['individual_id'] ?? '').toString(),
      storagePath: (json['storage_path'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      assignedAt: (json['assigned_at'] ?? '').toString(),
    );
  }
}

String? _readStringOrNull(dynamic value) {
  final String text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value
        .map((dynamic item) => item?.toString().trim() ?? '')
        .where((String item) => item.isNotEmpty)
        .toList();
  }
  final String? text = _readStringOrNull(value);
  if (text == null) return <String>[];
  return text
      .split(',')
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList();
}

Map<String, dynamic> _readStringMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

String? _joinNonEmpty(List<String?> values, {String separator = ', '}) {
  final List<String> filtered = values
      .map((String? item) => item?.trim() ?? '')
      .where((String item) => item.isNotEmpty)
      .toList();
  if (filtered.isEmpty) return null;
  return filtered.join(separator);
}
