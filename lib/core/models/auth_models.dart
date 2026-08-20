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

class DhiwayDetail {
  const DhiwayDetail({
    required this.spaceId,
    required this.schemaId,
    this.isDefault,
  });

  final String spaceId;
  final String schemaId;
  final bool? isDefault;

  factory DhiwayDetail.fromJson(Map<String, dynamic> json) {
    final dynamic rawDefault = json['default'] ?? json['is_default'];
    return DhiwayDetail(
      spaceId: _readStringOrNull(json['space_id'] ?? json['spaceId']) ?? '',
      schemaId: _readStringOrNull(json['schema_id'] ?? json['schemaId']) ?? '',
      isDefault: rawDefault is bool
          ? rawDefault
          : rawDefault == null
          ? null
          : rawDefault.toString().trim().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'space_id': spaceId.trim(),
      'schema_id': schemaId.trim(),
    };
    if (isDefault != null) {
      json['default'] = isDefault;
    }
    return json;
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
    this.humanSpaceId,
    this.productSpaceId,
    this.warrantySpaceId,
    this.humanSchemaId,
    this.productSchemaId,
    this.warrantySchemaId,
    this.dhiwaySpaceId,
  });

  final String orgName;
  final String email;
  final String phoneNumber;
  final String password;
  final String serviceType;
  final String? humanSpaceId;
  final String? productSpaceId;
  final String? warrantySpaceId;
  final String? humanSchemaId;
  final String? productSchemaId;
  final String? warrantySchemaId;
  final String? dhiwaySpaceId;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'org_name': orgName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'service_type': serviceType,
    };

    final String humanSpace = humanSpaceId?.trim() ?? '';
    final String productSpace = productSpaceId?.trim() ?? '';
    final String warrantySpace = warrantySpaceId?.trim() ?? '';
    final String humanSchema = humanSchemaId?.trim() ?? '';
    final String productSchema = productSchemaId?.trim() ?? '';
    final String warrantySchema = warrantySchemaId?.trim() ?? '';
    final String dhiwaySpace = dhiwaySpaceId?.trim() ?? '';

    if (humanSpace.isNotEmpty) json['human_space_id'] = humanSpace;
    if (productSpace.isNotEmpty) json['product_space_id'] = productSpace;
    if (warrantySpace.isNotEmpty) json['warranty_space_id'] = warrantySpace;
    if (humanSchema.isNotEmpty) json['human_schema_id'] = humanSchema;
    if (productSchema.isNotEmpty) json['product_schema_id'] = productSchema;
    if (warrantySchema.isNotEmpty) json['warranty_schema_id'] = warrantySchema;
    if (dhiwaySpace.isNotEmpty) json['dhiway_space_id'] = dhiwaySpace;

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
    this.spaceId,
    this.schemaId,
    this.useCases,
    this.dhiwaysDetails,
  });

  final String? gstin;
  final String? businessRegNumber;
  final String? addressLine1;
  final String? addressLine2;
  final String? addressLine3;
  final String? industryType;
  final String? spaceId;
  final String? schemaId;
  final Map<String, dynamic>? useCases;
  final List<DhiwayDetail>? dhiwaysDetails;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    void putIfNonEmpty(String key, String? value) {
      final String normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        json[key] = normalized;
      }
    }

    putIfNonEmpty('gstin', gstin);
    putIfNonEmpty('business_reg_number', businessRegNumber);
    putIfNonEmpty('address_line1', addressLine1);
    putIfNonEmpty('address_line2', addressLine2);
    putIfNonEmpty('address_line3', addressLine3);
    putIfNonEmpty('industry_type', industryType);
    putIfNonEmpty('space_id', spaceId);
    putIfNonEmpty('schema_id', schemaId);
    if (useCases != null && useCases!.isNotEmpty) {
      json['use_cases'] = useCases;
    }

    if (dhiwaysDetails != null) {
      final List<Map<String, dynamic>> details = dhiwaysDetails!
          .map((DhiwayDetail detail) => detail.toJson())
          .where(
            (Map<String, dynamic> detail) =>
                (detail['space_id'] ?? '').toString().trim().isNotEmpty ||
                (detail['schema_id'] ?? '').toString().trim().isNotEmpty,
          )
          .toList();
      if (details.isNotEmpty) {
        json['dhiways_details'] = details;
      }
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
    this.humanSpaceId,
    this.productSpaceId,
    this.warrantySpaceId,
    this.humanSchemaId,
    this.productSchemaId,
    this.warrantySchemaId,
    this.dhiwaySpaceId,
    this.dhiwaysDetails,
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
  final String? humanSpaceId;
  final String? productSpaceId;
  final String? warrantySpaceId;
  final String? humanSchemaId;
  final String? productSchemaId;
  final String? warrantySchemaId;
  final String? dhiwaySpaceId;
  final List<DhiwayDetail>? dhiwaysDetails;

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
    putIfNonEmpty('human_space_id', humanSpaceId);
    putIfNonEmpty('product_space_id', productSpaceId);
    putIfNonEmpty('warranty_space_id', warrantySpaceId);
    putIfNonEmpty('human_schema_id', humanSchemaId);
    putIfNonEmpty('product_schema_id', productSchemaId);
    putIfNonEmpty('warranty_schema_id', warrantySchemaId);
    putIfNonEmpty('dhiway_space_id', dhiwaySpaceId);
    if (dhiwaysDetails != null) {
      final List<Map<String, dynamic>> details = dhiwaysDetails!
          .map((DhiwayDetail detail) => detail.toJson())
          .where(
            (Map<String, dynamic> detail) =>
                (detail['space_id'] ?? '').toString().trim().isNotEmpty ||
                (detail['schema_id'] ?? '').toString().trim().isNotEmpty,
          )
          .toList();
      if (details.isNotEmpty) {
        json['dhiways_details'] = details;
      }
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
    required this.dhiwaySpaceId,
    required this.humanSpaceId,
    required this.productSpaceId,
    required this.warrantySpaceId,
    required this.humanSchemaId,
    required this.productSchemaId,
    required this.warrantySchemaId,
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
  final bool gstVerified;
  final bool emailVerified;
  final bool mobileVerified;
  final bool skillTreeInitiated;
  final List<DhiwayDetail> dhiwaysDetails;
  final String? dhiwaySpaceId;
  final String? humanSpaceId;
  final String? productSpaceId;
  final String? warrantySpaceId;
  final String? humanSchemaId;
  final String? productSchemaId;
  final String? warrantySchemaId;
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
    final List<DhiwayDetail> dhiwaysDetails = _readDhiwayDetails(json);
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
      dhiwaysDetails: dhiwaysDetails,
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
      humanSchemaId: _readStringOrNull(
        json['human_schema_id'] ?? json['humanSchemaId'],
      ),
      productSchemaId: _readStringOrNull(
        json['product_schema_id'] ?? json['productSchemaId'],
      ),
      warrantySchemaId: _readStringOrNull(
        json['warranty_schema_id'] ?? json['warrantySchemaId'],
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

List<DhiwayDetail> _readDhiwayDetails(Map<String, dynamic> json) {
  final dynamic rawDetails = json['dhiways_details'] ?? json['dhiwaysDetails'];
  final List<DhiwayDetail> details = <DhiwayDetail>[];
  final Set<String> seen = <String>{};

  void addUnique(String? spaceId, String? schemaId, {bool? isDefault}) {
    final String space = spaceId?.trim() ?? '';
    final String schema = schemaId?.trim() ?? '';
    if (space.isEmpty && schema.isEmpty) return;
    final String key = '$space|$schema|${isDefault ?? ''}';
    if (seen.add(key)) {
      details.add(
        DhiwayDetail(spaceId: space, schemaId: schema, isDefault: isDefault),
      );
    }
  }

  if (rawDetails is List) {
    final List<DhiwayDetail> parsed = rawDetails
        .whereType<Map>()
        .map((Map e) => DhiwayDetail.fromJson(Map<String, dynamic>.from(e)))
        .where(
          (DhiwayDetail detail) =>
              detail.spaceId.trim().isNotEmpty ||
              detail.schemaId.trim().isNotEmpty,
        )
        .toList();
    for (final DhiwayDetail detail in parsed) {
      addUnique(detail.spaceId, detail.schemaId, isDefault: detail.isDefault);
    }
  }

  addUnique(
    _readStringOrNull(json['space_id']),
    _readStringOrNull(json['schema_id']),
  );
  addUnique(
    _readStringOrNull(json['human_space_id'] ?? json['humanSpaceId']),
    _readStringOrNull(json['human_schema_id'] ?? json['humanSchemaId']),
  );
  addUnique(
    _readStringOrNull(json['product_space_id'] ?? json['productSpaceId']),
    _readStringOrNull(json['product_schema_id'] ?? json['productSchemaId']),
  );
  addUnique(
    _readStringOrNull(
      json['warranty_space_id'] ??
          json['warrenty_space_id'] ??
          json['warrantySpaceId'] ??
          json['warrentySpaceId'],
    ),
    _readStringOrNull(json['warranty_schema_id'] ?? json['warrantySchemaId']),
  );
  addUnique(
    _readStringOrNull(json['dhiway_space_id']),
    _readStringOrNull(json['dhiway_schema_id'] ?? json['dhiwaySchemaId']),
  );

  return details;
}

String? _joinNonEmpty(List<String?> values, {String separator = ', '}) {
  final List<String> filtered = values
      .map((String? item) => item?.trim() ?? '')
      .where((String item) => item.isNotEmpty)
      .toList();
  if (filtered.isEmpty) return null;
  return filtered.join(separator);
}
