import 'package:url_launcher/url_launcher.dart';

class GoogleOAuthService {
  GoogleOAuthService._();

  static const String _baseUrl =
      'https://trumarkz-api-54038467488.asia-south1.run.app';

  static Future<void> signInWithGoogle({String? loginHintEmail}) async {
    // Use in-app browser (Custom Tabs / SFSafariViewController) so the user
    // stays in-app but still uses a secure browser context.
    //
    // Note: To *force* the account chooser, backend should pass
    // `prompt=select_account` through to Google's authorize URL.
    final Map<String, String> qp = <String, String>{
      'prompt': 'select_account',
      if (loginHintEmail != null && loginHintEmail.trim().isNotEmpty)
        'login_hint': loginHintEmail.trim(),
    };
    final Uri uri = Uri.parse('$_baseUrl/auth/google/url').replace(
      queryParameters: qp,
    );
    final bool ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok) {
      throw Exception('Could not launch Google sign-in URL');
    }
  }
}
