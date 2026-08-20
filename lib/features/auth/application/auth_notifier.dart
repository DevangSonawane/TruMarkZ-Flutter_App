import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/token_storage.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _repo = ref.read(authRepositoryProvider);
  late final TokenStorage _tokenStorage = ref.read(tokenStorageProvider);

  String _normalizeLoginType(String? loginType) {
    final String normalized = (loginType ?? '').trim().toLowerCase();
    if (normalized == 'individual') return 'individual';
    if (normalized == 'organization') return 'organization';
    return 'organization';
  }

  Future<void> _persistLoginType(String loginType) async {
    await _tokenStorage.saveLoginType(_normalizeLoginType(loginType));
  }

  Future<AuthState> _loadCurrentUserState() async {
    final UserProfile me = await _repo.getMe();
    await _persistLoginType(me.loginType);
    return AuthState(
      status: AuthStatus.authenticated,
      userId: me.id,
      loginType: me.loginType,
      userProfile: me,
    );
  }

  String _routeForLoginType({
    required String loginType,
    required bool requiresOnboarding,
  }) {
    if (_normalizeLoginType(loginType) == 'individual') {
      return AppRouter.individualIdentityPath;
    }
    if (requiresOnboarding) {
      return AppRouter.orgOnboardingPath;
    }
    return AppRouter.dashboardPath;
  }

  String _routeForGoogleLogin({
    required String requestedLoginType,
    required String backendLoginType,
    required bool requiresOnboarding,
  }) {
    final String requested = _normalizeLoginType(requestedLoginType);
    final String backend = _normalizeLoginType(backendLoginType);

    // If the user started from the individual Google flow, never push them
    // into org onboarding just because the backend omitted or misreported the
    // account type. That keeps the first-time individual signup on the
    // individual path.
    if (requested == 'individual' || backend == 'individual') {
      return AppRouter.individualIdentityPath;
    }

    if (requiresOnboarding) {
      return AppRouter.orgOnboardingPath;
    }
    return AppRouter.dashboardPath;
  }

  @override
  Future<AuthState> build() async {
    final String? token = await _tokenStorage.getToken();
    if (token == null || token.trim().isEmpty) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    try {
      return _loadCurrentUserState();
    } on ApiException catch (_) {
      await _tokenStorage.clearAll();
      return const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      await _tokenStorage.clearAll();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginIndividual(String emailOrMobile, String password) async {
    state = AsyncData(
      (state.value ?? const AuthState()).copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );
    try {
      final LoginResponse login = await _repo.loginIndividual(
        emailOrMobile: emailOrMobile,
        password: password,
      );
      final UserProfile me = await _repo.getMe();
      final String resolvedLoginType = me.loginType.trim().isNotEmpty
          ? me.loginType
          : login.loginType;
      await _persistLoginType(resolvedLoginType);
      state = AsyncData(
        AuthState(
          status: AuthStatus.authenticated,
          userId: login.userId,
          loginType: resolvedLoginType,
          userProfile: me,
        ),
      );
      AppRouter.router.go(
        _routeForLoginType(
          loginType: resolvedLoginType,
          requiresOnboarding: login.requiresOnboarding,
        ),
      );
    } on ApiException catch (e) {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(
          isLoading: false,
          errorMessage: e.message,
        ),
      );
      rethrow;
    } catch (_) {
      const String msg = 'Something went wrong. Please try again.';
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(
          isLoading: false,
          errorMessage: msg,
        ),
      );
      throw const ApiException(statusCode: null, message: msg);
    } finally {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(isLoading: false),
      );
    }
  }

  Future<void> loginOrg(String emailOrMobile, String password) async {
    state = AsyncData(
      (state.value ?? const AuthState()).copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );
    try {
      final LoginResponse login = await _repo.loginOrg(
        emailOrMobile: emailOrMobile,
        password: password,
      );
      final UserProfile me = await _repo.getMe();
      final String resolvedLoginType = me.loginType.trim().isNotEmpty
          ? me.loginType
          : login.loginType;
      await _persistLoginType(resolvedLoginType);
      state = AsyncData(
        AuthState(
          status: AuthStatus.authenticated,
          userId: login.userId,
          loginType: resolvedLoginType,
          userProfile: me,
        ),
      );
      AppRouter.router.go(
        _routeForLoginType(
          loginType: resolvedLoginType,
          requiresOnboarding: login.requiresOnboarding,
        ),
      );
    } on ApiException catch (e) {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(
          isLoading: false,
          errorMessage: e.message,
        ),
      );
      rethrow;
    } catch (_) {
      const String msg = 'Something went wrong. Please try again.';
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(
          isLoading: false,
          errorMessage: msg,
        ),
      );
      throw const ApiException(statusCode: null, message: msg);
    } finally {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(isLoading: false),
      );
    }
  }

  Future<void> loginWithGoogle({
    required String idToken,
    required String userType,
  }) async {
    final String requestedLoginType = _normalizeLoginType(userType);
    state = AsyncData(
      (state.value ?? const AuthState()).copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );
    try {
      final LoginResponse login = await _repo.loginWithGoogle(
        idToken: idToken,
        userType: userType,
      );
      final UserProfile me = await _repo.getMe();
      final String resolvedLoginType = me.loginType.trim().isNotEmpty
          ? me.loginType
          : login.loginType;
      await _persistLoginType(resolvedLoginType);
      if (kDebugMode &&
          requestedLoginType == 'individual' &&
          _normalizeLoginType(resolvedLoginType) != 'individual') {
        debugPrint(
          '[Auth] Google login returned "${resolvedLoginType.trim()}" '
          'for an individual flow; routing to individual screen.',
        );
      }
      state = AsyncData(
        AuthState(
          status: AuthStatus.authenticated,
          userId: login.userId,
          loginType: resolvedLoginType,
          userProfile: me,
        ),
      );
      AppRouter.router.go(
        _routeForGoogleLogin(
          requestedLoginType: requestedLoginType,
          backendLoginType: resolvedLoginType,
          requiresOnboarding: login.requiresOnboarding,
        ),
      );
    } on ApiException catch (e) {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(
          isLoading: false,
          errorMessage: e.message,
        ),
      );
      rethrow;
    } catch (_) {
      const String msg = 'Something went wrong. Please try again.';
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(
          isLoading: false,
          errorMessage: msg,
        ),
      );
      throw const ApiException(statusCode: null, message: msg);
    } finally {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(isLoading: false),
      );
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _repo.forgotPassword(email);
      return true;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    try {
      await _repo.verifyOtp(email: email, otpCode: code);
      return true;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<UserProfile> updateServiceType(String serviceType) async {
    return updateOrganizationProfile(serviceType: serviceType);
  }

  Future<UserProfile> updateOrganizationProfile({
    String? organizationName,
    String? fullName,
    String? phoneNumber,
    String? gstin,
    String? businessRegNumber,
    String? addressLine1,
    String? addressLine2,
    String? addressLine3,
    String? serviceType,
    String? humanSpaceId,
    String? productSpaceId,
    String? warrantySpaceId,
    String? humanSchemaId,
    String? productSchemaId,
    String? warrantySchemaId,
    String? dhiwaySpaceId,
  }) async {
    state = AsyncData(
      (state.value ?? const AuthState()).copyWith(
        isLoading: true,
        errorMessage: null,
      ),
    );
    try {
      final UserProfile me = await _repo.updateOrganizationProfile(
        organizationName: organizationName,
        fullName: fullName,
        phoneNumber: phoneNumber,
        gstin: gstin,
        businessRegNumber: businessRegNumber,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        addressLine3: addressLine3,
        serviceType: serviceType,
        humanSpaceId: humanSpaceId,
        productSpaceId: productSpaceId,
        warrantySpaceId: warrantySpaceId,
        humanSchemaId: humanSchemaId,
        productSchemaId: productSchemaId,
        warrantySchemaId: warrantySchemaId,
        dhiwaySpaceId: dhiwaySpaceId,
      );
      final AuthState nextState = AuthState(
        status: AuthStatus.authenticated,
        userId: me.id,
        loginType: me.loginType,
        userProfile: me,
      );
      await _persistLoginType(me.loginType);
      state = AsyncData(nextState);
      return me;
    } on ApiException catch (e) {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(
          isLoading: false,
          errorMessage: e.message,
        ),
      );
      rethrow;
    } catch (_) {
      const String msg = 'Something went wrong. Please try again.';
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(
          isLoading: false,
          errorMessage: msg,
        ),
      );
      throw const ApiException(statusCode: null, message: msg);
    } finally {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(isLoading: false),
      );
    }
  }

  Future<VerifyGstResponse> verifyOrganizationGst() async {
    final AuthState? current = state.value;
    final UserProfile? profile = current?.userProfile;
    final String organizationName = profile?.organizationName?.trim() ?? '';
    final String gstin = profile?.gstin?.trim() ?? '';

    if (organizationName.isEmpty) {
      throw const ApiException(
        statusCode: null,
        message: 'Organization name is required before GST verification.',
      );
    }

    if (gstin.isEmpty) {
      throw const ApiException(
        statusCode: null,
        message: 'GSTIN is required before GST verification.',
      );
    }

    String maskGstin(String value) {
      if (value.length <= 4) return value;
      return '${value.substring(0, 2)}***${value.substring(value.length - 2)}';
    }

    if (kDebugMode) {
      debugPrint(
        '[Auth][GST] verify start org="$organizationName" gstin=${maskGstin(gstin)}',
      );
    }

    final VerifyGstResponse response = await _repo.verifyOrganizationGst(
      gstin: gstin,
    );

    if (kDebugMode) {
      debugPrint(
        '[Auth][GST] verify result verified=${response.gstVerified} '
        'gstin=${response.gstin} matchedOn=${response.matchedOn} '
        'gstStatus=${response.gstStatus} legalName=${response.legalName} '
        'tradeName=${response.tradeName} message=${response.message}',
      );
    }

    if (response.gstVerified) {
      await refreshCurrentUser();
    }

    return response;
  }

  Future<void> refreshCurrentUser() async {
    try {
      final AuthState nextState = await _loadCurrentUserState();
      state = AsyncData(nextState);
    } on ApiException catch (e) {
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(errorMessage: e.message),
      );
      rethrow;
    } catch (_) {
      const String msg = 'Something went wrong. Please try again.';
      state = AsyncData(
        (state.value ?? const AuthState()).copyWith(errorMessage: msg),
      );
      throw const ApiException(statusCode: null, message: msg);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
    AppRouter.router.go(AppRouter.roleSelectionPath);
  }
}
