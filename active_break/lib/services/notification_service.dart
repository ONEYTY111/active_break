import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder_and_tips.dart';
import '../services/database_service.dart';
import '../utils/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // macOS initialization settings
    const DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsMacOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('Notification service initialization completed');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return true;
  }

  /// Check notification permission status
  Future<bool> hasPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final permissions = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      final bool result = permissions?.isEnabled == true;
      return result ?? false;
    }
    return true;
  }

  /// Show immediate exercise reminder notification
  Future<void> showExerciseReminder({
    required int notificationId,
    required String activityName,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const String title = 'Exercise Reminder';
    final String body = customMessage ?? 'Time to exercise: $activityName';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'exercise_reminders',
          'Exercise Reminders',
          channelDescription: 'Scheduled exercise reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: 'exercise_reminder:$notificationId',
    );

    debugPrint('Showing exercise reminder notification: $title - $body');
  }

  /// Schedule timed exercise reminder notification
  Future<void> scheduleExerciseReminder({
    required int notificationId,
    required DateTime scheduledDate,
    required String activityName,
    String? customMessage,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    const String title = 'Exercise Reminder';
    final String body = customMessage ?? 'Time to exercise: $activityName';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'exercise_reminders',
          'Exercise Reminders',
          channelDescription: 'Scheduled exercise reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'exercise_reminder:$notificationId',
    );

    debugPrint('Scheduled exercise reminder notification: $title - $body, time: $scheduledDate');
  }

  /// Cancel specified notification
  Future<void> cancelNotification(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    debugPrint('Cancel notification: $notificationId');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('Cancel all notifications');
  }

  /// Get pending notification list
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Handle notification click event
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    debugPrint('Notification clicked: $payload');

    if (payload != null && payload.startsWith('exercise_reminder:')) {
      // Handle exercise reminder notification click
// Can navigate to exercise page or show exercise selection dialog
      _handleExerciseReminderTap(payload);
    }
  }

  /// Handle exercise reminder notification click
  void _handleExerciseReminderTap(String payload) {
    // Navigation logic can be added here, such as opening exercise page
// Since this is a service class, UI layer can be notified through event bus or callback
    debugPrint('Handle exercise reminder click: $payload');
  }

  /// Show test reminder notification
/// @author Author
/// @date Current date and time
  /// @return Future<void>
  Future<void> showTestReminder() async {
    await showExerciseReminder(
      notificationId: 9999,
      activityName: 'Test Exercise',
      customMessage: 'This is a test reminder. If you see this message, the reminder function is working properly!',
    );
  }

  /// Generate unique notification ID
  static int generateNotificationId(int userId, int activityTypeId) {
    return userId * 1000 + activityTypeId;
  }
}
