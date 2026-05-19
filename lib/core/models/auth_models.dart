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
  });

  final String orgName;
  final String email;
  final String phoneNumber;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'org_name': orgName,
    'email': email,
    'phone_number': phoneNumber,
    'password': password,
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
    required this.loginType,
    required this.fullName,
    required this.email,
    required this.mobile,
    required this.organizationName,
    required this.gstNumber,
    required this.businessRegistrationNumber,
    required this.industry,
    required this.address,
    required this.isActive,
    required this.isVerified,
    required this.emailVerified,
    required this.mobileVerified,
    required this.storagePath,
  });

  final String id;
  final String loginType;
  final String? fullName;
  final String email;
  final String? mobile;
  final String? organizationName;
  final String? gstNumber;
  final String? businessRegistrationNumber;
  final String? industry;
  final String? address;
  final bool isActive;
  final bool isVerified;
  final bool emailVerified;
  final bool mobileVerified;
  final String storagePath;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      loginType: (json['login_type'] ?? '').toString(),
      fullName: json['full_name']?.toString(),
      email: (json['email'] ?? '').toString(),
      mobile: json['mobile']?.toString(),
      organizationName: json['organization_name']?.toString(),
      gstNumber: json['gst_number']?.toString(),
      businessRegistrationNumber: json['business_registration_number']
          ?.toString(),
      industry: json['industry']?.toString(),
      address: json['address']?.toString(),
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
      emailVerified: json['email_verified'] == true,
      mobileVerified: json['mobile_verified'] == true,
      storagePath: (json['storage_path'] ?? '').toString(),
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
