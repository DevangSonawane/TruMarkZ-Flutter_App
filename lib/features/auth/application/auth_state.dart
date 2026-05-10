import '../../../core/models/auth_models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.userId,
    this.loginType,
    this.userProfile,
    this.errorMessage,
    this.isLoading = false,
  });

  final AuthStatus status;
  final String? userId;
  final String? loginType;
  final UserProfile? userProfile;
  final String? errorMessage;
  final bool isLoading;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? loginType,
    UserProfile? userProfile,
    Object? errorMessage = _sentinel,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      loginType: loginType ?? this.loginType,
      userProfile: userProfile ?? this.userProfile,
      errorMessage:
          identical(errorMessage, _sentinel) ? this.errorMessage : errorMessage as String?,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

const Object _sentinel = Object();
