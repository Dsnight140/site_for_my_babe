import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _lastPigeonNotifiedId;
  String? _lastMoodNotifiedKey;
  String? _lastWishNotifiedId;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'general_channel',
          'Общие',
          description: 'Важные уведомления от приложения',
          importance: Importance.high,
        ));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'pigeon_channel',
          'Голуби',
          description: 'Уведомления о письмах от половинки',
          importance: Importance.high,
        ));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'mood_channel',
          'Настроения',
          description: 'Уведомления о настроении партнёра',
          importance: Importance.defaultImportance,
        ));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'wishlist_channel',
          'Вишлист',
          description: 'Новые желания партнёра',
          importance: Importance.high,
        ));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // FCM setup
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // If we receive FCM in foreground, we can show local notification or let data drive it
      if (message.notification != null) {
        _showRawNotification(
          title: message.notification!.title ?? 'Уведомление',
          body: message.notification!.body ?? '',
          id: message.messageId.hashCode,
        );
      }
    });

    _ready = true;
  }

  Future<String?> getFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken;
        for (var attempt = 0; attempt < 10; attempt++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null && apnsToken.isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint('APNs token is not available yet; FCM token skipped.');
          return null;
        }
      }
      return await messaging.getToken();
    } catch (e) {
      debugPrint('FCM token unavailable: $e');
      return null;
    }
  }

  Future<void> _showRawNotification(
      {required String title, required String body, required int id}) async {
    if (!_ready) await init();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'general_channel',
            'Общие',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Raw notification failed: $e');
    }
  }

  Future<void> notifyIncomingPigeon({
    required String pigeonId,
    required String fromName,
  }) async {
    if (!_ready) await init();
    if (_lastPigeonNotifiedId == pigeonId) return;
    _lastPigeonNotifiedId = pigeonId;
    try {
      await _plugin.show(
        id: pigeonId.hashCode & 0x7fffffff,
        title: 'Тебе прилетел голубь 🕊️',
        body: '$fromName написал(а) письмо. Открой, пока оно не улетело.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pigeon_channel',
            'Голуби',
            channelDescription: 'Уведомления о письмах от половинки',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }
  }

  Future<void> notifyPartnerMood({
    required String partnerName,
    required String moodLabel,
    required String moodKey,
  }) async {
    if (!_ready) await init();
    if (_lastMoodNotifiedKey == moodKey) return;
    _lastMoodNotifiedKey = moodKey;
    try {
      await _plugin.show(
        id: moodKey.hashCode & 0x7fffffff,
        title: '$partnerName сменил(а) настроение',
        body: moodLabel,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'mood_channel',
            'Настроения',
            channelDescription: 'Уведомления о настроении партнёра',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Mood notification failed: $e');
    }
  }

  Future<void> notifyPartnerWish({
    required String wishId,
    required String partnerName,
    required String wishTitle,
  }) async {
    if (!_ready) await init();
    if (_lastWishNotifiedId == wishId) return;
    _lastWishNotifiedId = wishId;
    try {
      await _plugin.show(
        id: wishId.hashCode & 0x7fffffff,
        title: '$partnerName добавил(а) желание 🎁',
        body: wishTitle,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'wishlist_channel',
            'Вишлист',
            channelDescription: 'Новые желания партнёра',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Wishlist notification failed: $e');
    }
  }
}
