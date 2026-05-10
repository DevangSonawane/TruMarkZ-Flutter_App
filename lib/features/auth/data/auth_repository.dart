import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), ref.read(tokenStorageProvider));
});

class AuthRepository {
  AuthRepository(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<String> loginIndividual({
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

  Future<String> loginOrg({
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

  Future<String> _login({
    required String loginType,
    required String emailOrMobile,
    required String password,
    required bool rememberMe,
  }) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/login',
      data: LoginRequest(
        loginType: loginType,
        emailOrMobile: emailOrMobile,
        password: password,
        rememberMe: rememberMe,
      ).toJson(),
    );
    final LoginResponse parsed = LoginResponse.fromJson(res);
    if (parsed.accessToken.trim().isEmpty || parsed.userId.trim().isEmpty) {
      throw const ApiException(statusCode: null, message: 'Unexpected response. Please try again.');
    }
    await _tokenStorage.saveToken(parsed.accessToken);
    await _tokenStorage.saveUserId(parsed.userId);
    // Treat the requested login type as source of truth for routing.
    // Some backends may return a generic/incorrect `login_type` field.
    await _tokenStorage.saveLoginType(loginType);
    return parsed.userId;
  }

  Future<String> registerIndividual(RegisterIndividualRequest request) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/register/individual',
      data: request.toJson(),
    );
    final dynamic data = res['data'];
    final String userId = data is Map ? (data['user_id'] ?? '').toString() : '';
    if (userId.trim().isEmpty) {
      throw const ApiException(statusCode: null, message: 'Unexpected response. Please try again.');
    }
    return userId;
  }

  Future<String> registerOrg(RegisterOrgRequest request) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/register/organization',
      data: request.toJson(),
    );
    final dynamic data = res['data'];
    final String userId = data is Map ? (data['user_id'] ?? '').toString() : '';
    if (userId.trim().isEmpty) {
      throw const ApiException(statusCode: null, message: 'Unexpected response. Please try again.');
    }
    return userId;
  }

  Future<void> verifyOtp({
    required String identifier,
    required String otpCode,
    required String purpose,
  }) async {
    await _api.post(
      '/auth/verify-otp',
      data: OtpVerifyRequest(
        identifier: identifier,
        otpCode: otpCode,
        purpose: purpose,
      ).toJson(),
    );
  }

  Future<String?> forgotPassword(String emailOrMobile) async {
    final Map<String, dynamic> res = await _api.post(
      '/auth/forgot-password',
      data: <String, dynamic>{'email_or_mobile': emailOrMobile},
    );
    final dynamic data = res['data'];
    final String token = data is Map ? (data['reset_token'] ?? '').toString() : '';
    return token.trim().isEmpty ? null : token;
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _api.post(
      '/auth/reset-password',
      data: <String, dynamic>{'token': token, 'new_password': newPassword},
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
    throw const ApiException(statusCode: null, message: 'Unexpected response. Please try again.');
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
    throw const ApiException(statusCode: null, message: 'Unexpected response. Please try again.');
  }

  Future<List<AssignedIndividual>> getOrgIndividuals() async {
    final Map<String, dynamic> res = await _api.get('/auth/org/individuals');
    final dynamic data = res['data'];
    final dynamic individuals = data is Map ? data['individuals'] : null;
    if (individuals is List) {
      return individuals
          .whereType<Map>()
          .map((Map e) => AssignedIndividual.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const <AssignedIndividual>[];
  }

  Future<void> logout() => _tokenStorage.clearAll();
}
