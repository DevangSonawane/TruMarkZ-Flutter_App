import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingLogin {
  const PendingLogin({
    required this.loginType,
    required this.emailOrMobile,
    required this.password,
  });

  final String loginType; // "individual" | "organization"
  final String emailOrMobile;
  final String password;
}

final pendingLoginProvider = StateProvider<PendingLogin?>((ref) => null);

