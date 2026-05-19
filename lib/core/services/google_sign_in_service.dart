import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  GoogleSignInService._();

  // Backend's Google OAuth client_id (from `/auth/google/url` response).
  // Used so Google can mint an `idToken` that your backend can verify.
  static const String _serverClientId =
      '54038467488-qv20pmm5bigpiiepsp7btsh6hdd5r6n9.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _serverClientId,
    scopes: <String>['email', 'profile', 'openid'],
  );

  /// Opens the native Google account picker and returns the Google `idToken`
  /// plus the selected email.
  ///
  /// Send this token to backend `POST /auth/google` to login/signup.
  static Future<({String? idToken, String? email})> signIn() async {
    try {
      // Force chooser each time.
      await _googleSignIn.signOut();
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return (idToken: null, email: null);
      final GoogleSignInAuthentication auth = await account.authentication;
      return (idToken: auth.idToken, email: account.email);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleSignIn] signIn error: $e');
      }
      return (idToken: null, email: null);
    }
  }
}
