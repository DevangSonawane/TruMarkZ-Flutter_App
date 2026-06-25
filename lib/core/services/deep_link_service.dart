import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import 'token_storage.dart';

class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<String?>? _subscription;

  static Future<void> init(ProviderContainer container) async {
    await _handleInitialLink(container);
    _subscription ??= linkStream.listen(
      (String? link) async {
        if (link == null) return;
        await handleLink(link, container);
      },
      onError: (Object err, StackTrace st) {
        debugPrint('[DeepLink] stream error: $err');
      },
    );
  }

  static Future<void> dispose() async {
    final StreamSubscription<String?>? sub = _subscription;
    _subscription = null;
    await sub?.cancel();
  }

  static Future<void> _handleInitialLink(ProviderContainer container) async {
    try {
      final Uri? uri = await _appLinks.getInitialLink();
      if (uri == null) return;
      await handleUri(uri, container);
    } catch (e) {
      debugPrint('[DeepLink] initial link error: $e');
    }
  }

  static Future<void> handleLink(String link, ProviderContainer container) =>
      handleUri(Uri.parse(link), container);

  static Stream<String?> get linkStream =>
      _appLinks.uriLinkStream.map((Uri uri) => uri.toString());

  static Future<void> handleUri(Uri uri, ProviderContainer container) async {
    if (uri.path != AppRouter.authCallbackPath) return;

    final String? token = uri.queryParameters['token'];
    final bool requiresOnboarding =
        (uri.queryParameters['requires_onboarding'] ?? '').toLowerCase() ==
        'true';
    final String loginTypeRaw =
        (uri.queryParameters['login_type'] ??
                uri.queryParameters['type'] ??
                '')
            .trim()
            .toLowerCase();
    final String loginType = loginTypeRaw == 'organization'
        ? 'organization'
        : 'individual';

    if (token == null || token.trim().isEmpty) {
      AppRouter.router.go(
        '${AppRouter.authErrorPath}?message=${Uri.encodeComponent('Missing token in auth callback.')}',
      );
      return;
    }

    final TokenStorage tokenStorage = container.read(tokenStorageProvider);
    await tokenStorage.saveToken(token);
    await tokenStorage.saveLoginType(loginType);

    // Org onboarding is only applicable to organization accounts.
    if (requiresOnboarding && loginType == 'organization') {
      AppRouter.router.go(AppRouter.orgOnboardingPath);
      return;
    }

    AppRouter.router.go(
      loginType == 'individual'
          ? AppRouter.individualIdentityPath
          : AppRouter.dashboardPath,
    );
  }
}
