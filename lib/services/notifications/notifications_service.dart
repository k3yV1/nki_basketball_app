import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents, NotificationDetails, AndroidNotificationDetails, DarwinNotificationDetails, InitializationSettings, AndroidInitializationSettings, DarwinInitializationSettings, FlutterLocalNotificationsPlugin, Importance, Priority;

class NotificationsService {
    // SCHEDULE NOTIFICATION
    Future<void> scheduleNotification({
      required int id,
      required String title,
      required String body,
      required DateTime scheduledTime,
    }) async {
      if (!_initialized) {
        await initialize();
      }
      await notificationPlugins.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  final notificationPlugins = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  // INITIALIZE
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationPlugins.initialize(initializationSettings);

    _initialized = true;
  }

  // NOTIFICATIONS DETAILS SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'nki_basketball_channel',
        'NKI Basketball Notifications',
        channelDescription: 'Channel for NKI Basketball notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    required int id,
    required String title,
    required String body
  }) async {
    if (!_initialized) {
      await initialize();
    }

    await notificationPlugins.show(
      id,
      title,
      body,
      const NotificationDetails()
    );
  }
  // ON NOTIFICATION ACTION
}
