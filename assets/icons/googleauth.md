# Google OAuth - Flutter Integration Guide

## 🎯 Backend Handles Everything - Zero Extra Dependencies!

Your backend already has a complete Google OAuth flow. Flutter just needs to launch a browser and handle the callback.

---

## 📦 Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  url_launcher: ^6.2.0
  uni_links: ^0.5.1        # For deep link callback handling
  shared_preferences: ^2.2.0
  go_router: ^13.0.0       # Or your preferred router
```

---

## 🔧 Setup

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<activity ...>
  <!-- Deep link intent filter for auth callback -->
  <intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
      android:scheme="https"
      android:host="trumarkz.asynk.in"
      android:pathPrefix="/auth/callback"/>
  </intent-filter>
</activity>
```

### iOS — `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>https</string>
    </array>
  </dict>
</array>
```

---

## 🔄 Complete Flow

```
1. User taps "Sign in with Google"
        ↓
2. App opens browser → backend /auth/google/url
        ↓
3. Google authenticates user
        ↓
4. Google → Backend callback → Backend processes token
        ↓
5. Backend redirects to:
   https://trumarkz.asynk.in/auth/callback
     ?token=JWT_TOKEN
     &requires_onboarding=true/false
        ↓
6. Flutter app intercepts deep link
        ↓
7a. requires_onboarding = true  → Onboarding Screen
7b. requires_onboarding = false → Dashboard (direct)
        ↓
8. [If onboarding] Complete flow → Dashboard
```

---

## 📱 Implementation

### 1. Auth Service — `lib/services/auth_service.dart`

```dart
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl =
      'https://trumarkz-api-54038467488.asia-south1.run.app';
  static const String _tokenKey = 'access_token';

  /// Launch Google OAuth in browser
  static Future<void> signInWithGoogle() async {
    final uri = Uri.parse('$_baseUrl/auth/google/url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch Google sign-in URL');
    }
  }

  /// Save JWT token to local storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get stored JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear token on logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
```

---

### 2. Deep Link Handler — `lib/services/deep_link_service.dart`

```dart
import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class DeepLinkService {
  static StreamSubscription? _linkSubscription;

  /// Initialize deep link listener
  static Future<void> init(BuildContext context) async {
    // Handle cold start (app opened via deep link)
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        await _handleLink(initialLink, context);
      }
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }

    // Handle warm start (app already open, deep link received)
    _linkSubscription = linkStream.listen(
      (String? link) async {
        if (link != null) {
          await _handleLink(link, context);
        }
      },
      onError: (err) {
        debugPrint('Deep link stream error: $err');
      },
    );
  }

  static Future<void> _handleLink(String link, BuildContext context) async {
    final uri = Uri.parse(link);

    // Only handle our auth callback
    if (!uri.path.contains('/auth/callback')) return;

    final token = uri.queryParameters['token'];
    final requiresOnboarding =
        uri.queryParameters['requires_onboarding'] == 'true';

    if (token != null && token.isNotEmpty) {
      // Save JWT token
      await AuthService.saveToken(token);

      if (!context.mounted) return;

      // Route based on onboarding status
      if (requiresOnboarding) {
        // First-time login → Onboarding
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/onboarding',
          (route) => false,
        );
      } else {
        // Returning user → Dashboard directly
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (route) => false,
        );
      }
    } else {
      // Auth failed
      if (!context.mounted) return;
      Navigator.of(context).pushNamed('/auth/error');
    }
  }

  static void dispose() {
    _linkSubscription?.cancel();
  }
}
```

---

### 3. Login Screen — `lib/screens/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.signInWithGoogle();
      // Deep link handler (DeepLinkService) takes over after browser redirects back
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to open Google sign-in. Please try again.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / App Name
              const FlutterLogo(size: 80),
              const SizedBox(height: 48),

              const Text(
                'Welcome to Trumarkz',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.asset(
                          'assets/google_icon.png',
                          height: 24,
                          width: 24,
                        ),
                  label: Text(
                    _isLoading ? 'Opening...' : 'Sign in with Google',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 4. Auth Callback Screen — `lib/screens/auth_callback_screen.dart`

> This screen is shown briefly while the deep link is being processed.

```dart
import 'package:flutter/material.dart';

class AuthCallbackScreen extends StatelessWidget {
  const AuthCallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Completing sign in...'),
          ],
        ),
      ),
    );
  }
}
```

---

### 5. Auth Error Screen — `lib/screens/auth_error_screen.dart`

```dart
import 'package:flutter/material.dart';

class AuthErrorScreen extends StatelessWidget {
  final String? message;
  const AuthErrorScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Authentication Error',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 6. Onboarding Screen — `lib/screens/onboarding_screen.dart`

> Shown only for first-time org sign-ups (`requires_onboarding: true`).

```dart
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _orgNameController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _completeOnboarding() async {
    if (_orgNameController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      // TODO: Call your backend onboarding API here
      // await OnboardingService.submit(orgName: _orgNameController.text);

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Onboarding failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Setup')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome! Let\'s set up your organization.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _orgNameController,
              decoration: const InputDecoration(
                labelText: 'Organization Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _completeOnboarding,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Continue to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 7. Router & App Entry — `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/deep_link_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_callback_screen.dart';
import 'screens/auth_error_screen.dart';

void main() {
  runApp(const TrumarkzApp());
}

class TrumarkzApp extends StatefulWidget {
  const TrumarkzApp({super.key});

  @override
  State<TrumarkzApp> createState() => _TrumarkzAppState();
}

class _TrumarkzAppState extends State<TrumarkzApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trumarkz',
      navigatorKey: _navigatorKey,
      onGenerateRoute: _onGenerateRoute,
      home: const SplashRouter(),
    );
  }
}

/// Decides initial route: already logged in → Dashboard, else → Login
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Initialize deep link handler
    await DeepLinkService.init(context);

    // If user already has a token → go straight to dashboard
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/login':
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case '/dashboard':
      return MaterialPageRoute(builder: (_) => const DashboardScreen());
    case '/onboarding':
      return MaterialPageRoute(builder: (_) => const OnboardingScreen());
    case '/auth/callback':
      return MaterialPageRoute(builder: (_) => const AuthCallbackScreen());
    case '/auth/error':
      return MaterialPageRoute(builder: (_) => const AuthErrorScreen());
    default:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
  }
}

final _navigatorKey = GlobalKey<NavigatorState>();
```

---

## 🔒 Security Notes

- JWT tokens are returned in the URL — save immediately to `SharedPreferences` and do not log the URL.
- Token expires after **1 hour** (`JWT_EXPIRE_MINUTES`). Implement a refresh flow or re-auth prompt.
- Always use HTTPS in production (already configured on your backend ✅).
- Never hardcode secrets in Flutter code — all OAuth secrets live on the backend.

---

## 🧪 Testing Checklist

1. ☐ Deploy backend with latest changes
2. ☐ Add deep link scheme to `AndroidManifest.xml` and `Info.plist`
3. ☐ Run `flutter pub get`
4. ☐ Test **new org sign-up** → should land on Onboarding screen
5. ☐ Complete onboarding → should land on Dashboard
6. ☐ Sign out, sign in again → should skip onboarding and go directly to Dashboard
7. ☐ Test error case (deny Google permission) → should land on Auth Error screen

---

## 📋 Summary — What You Need to Build

| What | File |
|------|------|
| Google sign-in button | `lib/screens/login_screen.dart` |
| Deep link callback handler | `lib/services/deep_link_service.dart` |
| Token storage | `lib/services/auth_service.dart` |
| Auth callback loading screen | `lib/screens/auth_callback_screen.dart` |
| Auth error screen | `lib/screens/auth_error_screen.dart` |
| Onboarding screen (first login only) | `lib/screens/onboarding_screen.dart` |
| Router & splash (auto-login check) | `lib/main.dart` |

**No Google SDK needed. No extra OAuth packages. Backend handles everything.**