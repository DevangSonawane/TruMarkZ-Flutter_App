import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/auth_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/token_storage.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _repo = ref.read(authRepositoryProvider);
  late final TokenStorage _tokenStorage = ref.read(tokenStorageProvider);

  @override
  Future<AuthState> build() async {
    final String? token = await _tokenStorage.getToken();
    if (token == null || token.trim().isEmpty) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    try {
      final UserProfile me = await _repo.getMe();
      return AuthState(
        status: AuthStatus.authenticated,
        userId: me.id,
        loginType: me.loginType,
        userProfile: me,
      );
    } on ApiException catch (_) {
      await _tokenStorage.clearAll();
      return const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      await _tokenStorage.clearAll();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> loginIndividual(String emailOrMobile, String password) async {
    state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: true, errorMessage: null));
    try {
      final String userId = await _repo.loginIndividual(emailOrMobile: emailOrMobile, password: password);
      final UserProfile me = await _repo.getMe();
      state = AsyncData(
        AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          loginType: me.loginType,
          userProfile: me,
        ),
      );
      AppRouter.router.go(AppRouter.individualIdentityPath);
    } on ApiException catch (e) {
      state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: false, errorMessage: e.message));
      rethrow;
    } catch (_) {
      const String msg = 'Something went wrong. Please try again.';
      state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: false, errorMessage: msg));
      throw const ApiException(statusCode: null, message: msg);
    } finally {
      state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: false));
    }
  }

  Future<void> loginOrg(String emailOrMobile, String password) async {
    state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: true, errorMessage: null));
    try {
      final String userId = await _repo.loginOrg(emailOrMobile: emailOrMobile, password: password);
      final UserProfile me = await _repo.getMe();
      state = AsyncData(
        AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          loginType: me.loginType,
          userProfile: me,
        ),
      );
      AppRouter.router.go(AppRouter.dashboardPath);
    } on ApiException catch (e) {
      state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: false, errorMessage: e.message));
      rethrow;
    } catch (_) {
      const String msg = 'Something went wrong. Please try again.';
      state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: false, errorMessage: msg));
      throw const ApiException(statusCode: null, message: msg);
    } finally {
      state = AsyncData((state.value ?? const AuthState()).copyWith(isLoading: false));
    }
  }

  Future<bool> forgotPassword(String emailOrMobile) async {
    try {
      await _repo.forgotPassword(emailOrMobile);
      return true;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verifyOtp(String identifier, String code, String purpose) async {
    try {
      await _repo.verifyOtp(identifier: identifier, otpCode: code, purpose: purpose);
      return true;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
    AppRouter.router.go(AppRouter.roleSelectionPath);
  }
}
