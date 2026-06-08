import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'vault_keeper.dart';
import 'wire_client.dart';

// Background isolate entry — must be top-level.
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage _) async {
  // The OS draws the notification itself; nothing to do here.
}

const String _channelId = 'magma_alerts';
const String _channelLabel = 'Magma alerts';
const String _channelDescription = 'Eruption updates and offers';
const String _smallIconRes = '@drawable/ic_lava_alert';

/// Firebase Messaging facade. Handles permissions, local display of foreground
/// messages, and persistence of one-shot push URLs.
class SignalCourier {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final VaultKeeper _vault;
  FirebaseMessaging? _fcm;
  String? _token;
  bool _booted = false;

  /// Live (warm) push tap → load URL into the WebView without persisting it.
  void Function(String url)? onWarmUrl;

  /// FCM token rotation hook.
  void Function(String token)? onTokenRotate;

  SignalCourier(this._vault);

  String? get token => _token;

  Future<void> boot() async {
    if (_booted) return;
    try {
      await Firebase.initializeApp();
      _fcm = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

      await _prepareLocal();

      _token = await _fcm!.getToken();

      _fcm!.onTokenRefresh.listen((fresh) {
        _token = fresh;
        onTokenRotate?.call(fresh);
      });

      FirebaseMessaging.onMessage.listen(_handleForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleWarmTap);

      final cold = await _fcm!.getInitialMessage();
      if (cold != null) _handleColdTap(cold);

      _booted = true;
    } catch (_) {
      // Firebase not configured — gray flow continues without push.
    }
  }

  Future<void> _prepareLocal() async {
    const androidInit = AndroidInitializationSettings(_smallIconRes);
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (res) {
        if (res.payload == null) return;
        try {
          final data = jsonDecode(res.payload!) as Map<String, dynamic>;
          final url = data['url'] as String?;
          if (url != null && url.isNotEmpty) onWarmUrl?.call(url);
        } catch (_) {}
      },
    );

    if (Platform.isAndroid) {
      final droid = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await droid?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelLabel,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
    }
  }

  Future<bool> askPermission() async {
    if (_fcm == null) return false;
    final settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    await _vault.markAlertOptIn(granted);
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Android 13+ won't re-prompt — record it permanently.
      await _vault.markOsBlockedAlerts();
    }
    return granted;
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    final note = message.notification;
    if (note == null) return;
    if (!Platform.isAndroid) return;

    final picture = note.android?.imageUrl;
    AndroidNotificationDetails? androidDetails;
    if (picture != null && picture.isNotEmpty) {
      final bytes = await _fetchImage(picture);
      if (bytes != null) {
        androidDetails = AndroidNotificationDetails(
          _channelId,
          _channelLabel,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: _smallIconRes,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }

    androidDetails ??= const AndroidNotificationDetails(
      _channelId,
      _channelLabel,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: _smallIconRes,
    );

    final payload =
        message.data.isNotEmpty ? jsonEncode(message.data) : null;

    await _local.show(
      note.hashCode,
      note.title,
      note.body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  void _handleColdTap(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) {
      _vault.writePushUrl(url);
    }
  }

  void _handleWarmTap(RemoteMessage message) {
    final url = message.data['url'] as String?;
    if (url != null && url.isNotEmpty) {
      onWarmUrl?.call(url);
    }
  }

  Future<Uint8List?> _fetchImage(String url) async {
    try {
      final res =
          await wire.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return res.bodyBytes;
    } catch (_) {}
    return null;
  }
}
