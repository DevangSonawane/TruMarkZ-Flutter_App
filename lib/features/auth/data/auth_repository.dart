import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider),
    ref.read(tokenStorageProvider),
  );
});

final organizationIndustryTypeProvider = FutureProvider.family<String?, String>(
  (ref, orgId) async {
    final String id = orgId.trim();
    if (id.isEmpty) return null;
    return ref
        .read(authRepositoryProvider)
        .getOrganizationIndustryType(orgId: id);
  },
);

class AuthRepository {
  AuthRepository(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<LoginResponse> loginIndividual({
    required String emailOrMobile,
    required String password,
    bool rememberMe = false,
  }) async {
    return _login(
      loginType: 'individual',
      emailOrMobile: emailOrMobile,
      password: password,
      rememberMe: rememberMe,
    );
  }

  Future<LoginResponse> loginOrg({
    required String emailOrMobile,
    required String password,
    bool rememberMe = false,
  }) async {
    return _login(
      loginType: 'organization',
      emailOrMobile: emailOrMobile,
      password: password,
      rememberMe: rememberMe,
    );
  }

  Future<LoginResponse> loginWithGoogle({
    required String idToken,
    required String userType,
  }) async {
    final String normalized = userType.trim().toLowerCase() == 'individual'
        ? 'individual'
        : 'organization';
    final Map<String, dynamic> res = await _api.post(
      '/auth/google?user_type=${Uri.encodeComponent(normalized)}',
      data: <String, dynamic>{'token': idToken},
      skipAuth: true,
    );
    final LoginResponse parsed = LoginResponse.fromJson(res);
    if (parsed.accessToken.trim().isEmpty || parsed.userId.trim().isEmpty) {
      throw const ApiException(
        statusCode: null,
        message: 'Unexpected response. Please try again.',
      );
    }

    await _tokenStorage.saveToken(parsed.accessToken);
    await _tokenStorage.saveUserId(parsed.userId);
    return parsed;
  }

  Future<LoginResponse> _login({
    required String loginType,
    required String emailOrMobile,
    required String password,
    required bool rememberMe,
  }) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/login',
      data: LoginRequest(
        loginType: loginType,
        email: emailOrMobile,
        password: password,
        rememberMe: rememberMe,
      ).toJson(),
    );
    final LoginResponse parsed = LoginResponse.fromJson(res);
    if (parsed.accessToken.trim().isEmpty || parsed.userId.trim().isEmpty) {
      throw const ApiException(
        statusCode: null,
        message: 'Unexpected response. Please try again.',
      );
    }
    await _tokenStorage.saveToken(parsed.accessToken);
    await _tokenStorage.saveUserId(parsed.userId);
    return parsed;
  }

  Future<void> registerIndividual(RegisterIndividualRequest request) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/register/individual',
      data: request.toJson(),
    );
    // Some backend deployments may respond without a `data.user_id` payload
    // (e.g. only a success `message`). If the request succeeded (2xx), treat it
    // as success and let the OTP step continue.
    final dynamic data = res['data'];
    if (data is Map) {
      final String userId = (data['user_id'] ?? '').toString();
      if (userId.trim().isNotEmpty) return;
    }
  }

  Future<void> signupOrganization(SignupOrganizationRequest request) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/signup/organization',
      data: request.toJson(),
    );
    // API returns user_id at top-level per docs; accept either shape.
    final String directUserId = (res['user_id'] ?? '').toString();
    if (directUserId.trim().isNotEmpty) return;
    final dynamic data = res['data'];
    final String nestedUserId = data is Map
        ? (data['user_id'] ?? '').toString()
        : '';
    if (nestedUserId.trim().isNotEmpty) return;
  }

  Future<void> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    await _api.post(
      '/auth/verify-otp',
      data: OtpVerifyRequest(email: email, otpCode: otpCode).toJson(),
    );
  }

  Future<void> resendOtp({required String email}) async {
    await _api.post(
      '/auth/resend-otp',
      data: ResendOtpRequest(email: email).toJson(),
    );
  }

  Future<void> completeOrgOnboarding(OrgOnboardingRequest request) async {
    await _api.post('/auth/onboarding', data: request.toJson());
  }

  Future<String?> getOrganizationIndustryType({required String orgId}) async {
    final String id = orgId.trim();
    if (id.isEmpty) return null;
    final dynamic res = await _api.verificationGetAny(
      '/auth/organization/${Uri.encodeComponent(id)}/industry-type',
    );
    if (res is String) {
      final String value = res.trim();
      return value.isEmpty ? null : value;
    }
    if (res is Map) {
      final dynamic data =
          res['data'] ?? res['industry_type'] ?? res['industryType'];
      if (data is String) {
        final String value = data.trim();
        return value.isEmpty ? null : value;
      }
      if (data is List) {
        final List<String> values = data
            .map((dynamic e) => e?.toString().trim() ?? '')
            .where((String e) => e.isNotEmpty)
            .toList();
        if (values.isEmpty) return null;
        return values.length == 1 ? values.first : values.join(', ');
      }
      if (data != null) {
        final String value = data.toString().trim();
        return value.isEmpty ? null : value;
      }
    }
    final String value = res?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(
      '/auth/forgot-password',
      data: <String, dynamic>{'email': email},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await _api.post(
      '/auth/reset-password',
      data: <String, dynamic>{
        'email': email,
        'otp_code': otpCode,
        'new_password': newPassword,
      },
    );
  }

  Future<UserProfile> getMe() async {
    final Map<String, dynamic> res = await _api.get('/auth/me');
    return UserProfile.fromJson(res);
  }

  Future<AssignIndividualResult> assignIndividualToOrg({
    required String individualEmailOrMobile,
  }) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/org/assign-individual',
      data: AssignIndividualRequest(
        individualEmailOrMobile: individualEmailOrMobile,
      ).toJson(),
    );
    final dynamic data = res['data'];
    if (data is Map) {
      return AssignIndividualResult.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException(
      statusCode: null,
      message: 'Unexpected response. Please try again.',
    );
  }

  Future<InviteIndividualResult> inviteIndividualToOrg({
    String? email,
    String? mobile,
  }) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/org/invite-individual',
      data: InviteIndividualRequest(email: email, mobile: mobile).toJson(),
    );
    final dynamic data = res['data'];
    if (data is Map) {
      return InviteIndividualResult.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException(
      statusCode: null,
      message: 'Unexpected response. Please try again.',
    );
  }

  Future<List<AssignedIndividual>> getOrgIndividuals() async {
    final Map<String, dynamic> res = await _api.get('/auth/org/individuals');
    final dynamic data = res['data'];
    final dynamic individuals = data is Map ? data['individuals'] : null;
    if (individuals is List) {
      return individuals
          .whereType<Map>()
          .map(
            (Map e) =>
                AssignedIndividual.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return const <AssignedIndividual>[];
  }

  Future<void> logout() => _tokenStorage.clearAll();
}
