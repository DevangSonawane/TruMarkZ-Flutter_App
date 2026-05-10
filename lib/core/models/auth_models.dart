class LoginRequest {
  const LoginRequest({
    required this.loginType,
    required this.emailOrMobile,
    required this.password,
    this.rememberMe = false,
  });

  final String loginType;
  final String emailOrMobile;
  final String password;
  final bool rememberMe;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'login_type': loginType,
        'email_or_mobile': emailOrMobile,
        'password': password,
        'remember_me': rememberMe,
      };
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.loginType,
  });

  final String accessToken;
  final String tokenType;
  final String userId;
  final String loginType;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: (json['access_token'] ?? '').toString(),
      tokenType: (json['token_type'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      loginType: (json['login_type'] ?? '').toString(),
    );
  }
}

class RegisterIndividualRequest {
  const RegisterIndividualRequest({
    required this.fullName,
    required this.email,
    this.mobile,
    required this.address,
    required this.password,
  });

  final String fullName;
  final String email;
  final String? mobile;
  final String address;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'email': email,
        'mobile': mobile,
        'address': address,
        'password': password,
      };
}

class RegisterOrgRequest {
  const RegisterOrgRequest({
    required this.organizationName,
    required this.gstNumber,
    required this.businessRegistrationNumber,
    required this.address,
    required this.email,
    this.mobile,
    required this.password,
  });

  final String organizationName;
  final String gstNumber;
  final String businessRegistrationNumber;
  final String address;
  final String email;
  final String? mobile;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'organization_name': organizationName,
        'gst_number': gstNumber,
        'business_registration_number': businessRegistrationNumber,
        'address': address,
        'email': email,
        'mobile': mobile,
        'password': password,
      };
}

class OtpVerifyRequest {
  const OtpVerifyRequest({
    required this.identifier,
    required this.otpCode,
    required this.purpose,
  });

  final String identifier;
  final String otpCode;
  final String purpose; // "registration" | "forgot_password"

  Map<String, dynamic> toJson() => <String, dynamic>{
        'identifier': identifier,
        'otp_code': otpCode,
        'purpose': purpose,
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
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
      emailVerified: json['email_verified'] == true,
      mobileVerified: json['mobile_verified'] == true,
      storagePath: (json['storage_path'] ?? '').toString(),
    );
  }
}

