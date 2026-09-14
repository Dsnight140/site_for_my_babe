import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _lastPigeonNotifiedId;
  String? _lastMoodNotifiedKey;

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
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _ready = true;
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
}
