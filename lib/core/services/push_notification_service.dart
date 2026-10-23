import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';

/// The background entry point must remain top-level so Android can invoke it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationEvent {
  const PushNotificationEvent({required this.message, required this.opened});

  final RemoteMessage message;
  final bool opened;

  String get notificationType =>
      (message.data['notification_type'] ?? '').toString().trim();
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final PushNotificationService service = PushNotificationService(
    FirebaseMessaging.instance,
    ref.read(apiClientProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

class PushNotificationService {
  PushNotificationService(this._messaging, this._api)
    : _localNotifications = FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final ApiClient _api;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final StreamController<PushNotificationEvent> _events =
      StreamController<PushNotificationEvent>.broadcast();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _started = false;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'trumarkz_notifications',
        'TruMarkZ notifications',
        description: 'Updates about your TruMarkZ account and batches.',
        importance: Importance.defaultImportance,
      );

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Stream<PushNotificationEvent> get events => _events.stream;

  /// Installs delivery and tap listeners. It does not show a permission prompt.
  Future<void> start() async {
    if (!_isSupportedPlatform) return;
    if (_started) return;
    _started = true;
    await _initializeLocalNotifications();
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) async {
      await _showForegroundNotification(message);
      _events.add(PushNotificationEvent(message: message, opened: false));
    });
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) =>
          _events.add(PushNotificationEvent(message: message, opened: true)),
    );
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      _registerToken,
      onError: (Object error, StackTrace stackTrace) {},
    );

    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _events.add(PushNotificationEvent(message: initialMessage, opened: true));
    }
  }

  /// Registers the FCM token for the authenticated account. Asking for OS
  /// permission is deliberately opt-in so app relaunches never reprompt users.
  Future<void> activateForAuthenticatedUser({
    bool requestPermission = false,
  }) async {
    if (!_isSupportedPlatform) return;
    await start();
    if (requestPermission) {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    }
    try {
      final String? token = await _messaging.getToken();
      if (token != null && token.trim().isNotEmpty) await _registerToken(token);
    } catch (_) {
      // Push registration is best-effort and must never block sign-in.
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (!_isSupportedPlatform) return;
    try {
      final String? token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return;
      await _api.deleteAny(
        '/push/tokens?token=${Uri.encodeQueryComponent(token)}',
      );
    } catch (_) {
      // The backend also reassigns a reused token at the next login.
    }
  }

  Future<void> _registerToken(String token) async {
    final String cleanToken = token.trim();
    if (cleanToken.isEmpty) return;
    final String platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => '',
    };
    if (platform.isEmpty || kIsWeb) return;
    try {
      await _api.post(
        '/push/tokens',
        data: <String, String>{'token': cleanToken, 'platform': platform},
      );
    } catch (_) {
      // A later refresh or authenticated launch retries registration.
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String payload = response.payload?.trim() ?? '';
        if (payload.isEmpty) return;
        try {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            jsonDecode(payload) as Map,
          );
          _events.add(
            PushNotificationEvent(
              message: RemoteMessage(data: data),
              opened: true,
            ),
          );
        } catch (_) {
          // Navigation is optional; malformed payloads must not crash the app.
        }
      },
    );
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final String title = message.notification?.title?.trim().isNotEmpty == true
        ? message.notification!.title!
        : 'TruMarkZ update';
    final String body = message.notification?.body?.trim().isNotEmpty == true
        ? message.notification!.body!
        : 'You have a new account update.';
    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'trumarkz_notifications',
          'TruMarkZ notifications',
          channelDescription:
              'Updates about your TruMarkZ account and batches.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_notification',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    _events.close();
  }
}
