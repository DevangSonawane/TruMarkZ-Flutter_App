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

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final String inferredType = (json['login_type'] ?? json['user_type'] ?? '')
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
      'mobile': mobile,
      'password': password,
    };
    if (address != null && address!.trim().isNotEmpty) {
      json['address'] = address;
    }
    return json;
  }
}

class SignupOrganizationRequest {
  const SignupOrganizationRequest({
    required this.orgName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.serviceType,
  });

  final String orgName;
  final String email;
  final String phoneNumber;
  final String password;
  final String serviceType;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'org_name': orgName,
    'email': email,
    'phone_number': phoneNumber,
    'password': password,
    'service_type': serviceType,
  };
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
    required this.industryType,
    required this.gstin,
    required this.businessRegNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.addressLine3,
    required this.useCases,
  });

  final List<String> industryType;
  final String gstin;
  final String businessRegNumber;
  final String addressLine1;
  final String addressLine2;
  final String addressLine3;
  final Map<String, dynamic> useCases;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'industry_type': industryType,
    'gstin': gstin,
    'business_reg_number': businessRegNumber,
    'address_line1': addressLine1,
    'address_line2': addressLine2,
    'address_line3': addressLine3,
    'use_cases': useCases,
  };
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
    required this.emailVerified,
    required this.mobileVerified,
    required this.skillTreeInitiated,
    required this.dhiwaySpaceId,
    required this.humanSpaceId,
    required this.productSpaceId,
    required this.warrantySpaceId,
    required this.storagePath,
    required this.createdAt,
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
  final bool emailVerified;
  final bool mobileVerified;
  final bool skillTreeInitiated;
  final String? dhiwaySpaceId;
  final String? humanSpaceId;
  final String? productSpaceId;
  final String? warrantySpaceId;
  final String storagePath;
  final DateTime? createdAt;

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
      json['organization_name'],
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
      emailVerified: emailVerified,
      mobileVerified: json['mobile_verified'] == true,
      skillTreeInitiated: json['skill_tree_initiated'] == true,
      dhiwaySpaceId: _readStringOrNull(json['dhiway_space_id']),
      humanSpaceId: _readStringOrNull(
        json['human_space_id'] ?? json['humanSpaceId'],
      ),
      productSpaceId: _readStringOrNull(
        json['product_space_id'] ?? json['productSpaceId'],
      ),
      warrantySpaceId: _readStringOrNull(
        json['warranty_space_id'] ??
            json['warrenty_space_id'] ??
            json['warrantySpaceId'] ??
            json['warrentySpaceId'],
      ),
      storagePath: (json['storage_path'] ?? '').toString(),
      createdAt: createdAt,
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
