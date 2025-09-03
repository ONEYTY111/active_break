import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  /// Show immediate exercise reminder notification with enhanced logging
  /// @author Author
  /// @date Current date and time
  /// @param notificationId 通知ID
  /// @param activityName 活动名称
  /// @param customMessage 自定义消息
  /// @return Future<void>
  /// @throws Exception 当通知发送失败时抛出异常
  Future<void> showExerciseReminder({
    required int notificationId,
    required String activityName,
    String? customMessage,
    bool useEnglish = false,
  }) async {
    try {
      debugPrint('Preparing to send exercise reminder: ID=$notificationId, activity=$activityName');
      
      if (!_isInitialized) {
        debugPrint('Notification service not initialized, initializing...');
        await initialize();
        debugPrint('Notification service initialization completed');
      }

      final String title = useEnglish ? 'Exercise Reminder' : '运动提醒';
      final String body = customMessage ?? (useEnglish ? 'Time to exercise: $activityName' : '该运动了: $activityName');
      
      debugPrint('Notification content: title="$title", body="$body"');

      // 增强Android通知设置，确保在锁屏和关屏状态下显示
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
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
            visibility: NotificationVisibility.public, // 在锁屏上完全显示
            fullScreenIntent: true, // 尝试在锁屏上全屏显示
            category: AndroidNotificationCategory.alarm, // 设置为闹钟类别，提高优先级
          );

      // 增强iOS通知设置，确保在锁屏状态下显示
      // 增强iOS通知设置，确保在锁屏和关屏状态下显示
        const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive, // 设置为时间敏感，提高优先级
            // 以下设置确保通知在后台和锁屏状态下显示
            threadIdentifier: 'exercise_reminder_thread', // 使用线程标识符分组通知
            categoryIdentifier: 'exercise', // 设置通知类别
            attachments: null, // 不使用附件
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        macOS: iOSPlatformChannelSpecifics,
      );

      debugPrint('Sending notification...');
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: 'exercise_reminder:$notificationId',
      );

      debugPrint('✅ Exercise reminder notification sent successfully: $title - $body');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to send exercise reminder notification: $e');
      debugPrint('Error stack: $stackTrace');
      rethrow;
    }
  }

  /// Schedule timed exercise reminder notification
  /// @author Author
  /// @date Current date and time
  /// @param notificationId 通知ID
  /// @param scheduledDate 调度时间
  /// @param activityName 活动名称
  /// @param customMessage 自定义消息
  /// @return Future<void>
  /// @throws Exception 当通知调度失败时抛出异常
  Future<void> scheduleExerciseReminder({
    required int notificationId,
    required DateTime scheduledDate,
    required String activityName,
    String? customMessage,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      const String title = 'Exercise Reminder';
      final String body = customMessage ?? 'Time to exercise: $activityName';

      // 增强Android通知设置，确保在锁屏和关屏状态下显示
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'exercise_reminders',
            'Exercise Reminders',
            channelDescription: 'Scheduled exercise reminder notifications',
            importance: Importance.max, // 使用最高重要性
            priority: Priority.max, // 使用最高优先级
            showWhen: true,
            enableVibration: true,
            playSound: true,
            enableLights: true,
            ledColor: Color.fromARGB(255, 255, 0, 0),
            ledOnMs: 1000,
            ledOffMs: 500,
            visibility: NotificationVisibility.public, // 在锁屏上完全显示
            category: AndroidNotificationCategory.alarm, // 设置为闹钟类别
            fullScreenIntent: true, // 尝试在锁屏上全屏显示
            autoCancel: false, // 不自动取消，确保用户看到
          );

      // 增强iOS通知设置，确保在锁屏和关屏状态下显示
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive, // 时间敏感
            threadIdentifier: 'exercise_reminder_thread',
            categoryIdentifier: 'exercise',
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // 允许在设备休眠时精确调度
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'exercise_reminder:$notificationId',
        matchDateTimeComponents: null, // 不重复，只触发一次
      );

      debugPrint('✅ Scheduled exercise reminder notification: $title - $body, time: $scheduledDate');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to schedule exercise reminder notification: $e');
      debugPrint('Error stack: $stackTrace');
      rethrow;
    }
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

  /// Show test reminder notification with detailed logging
  /// @author Author
  /// @date Current date and time
  /// @return Future<Map<String, dynamic>> 返回测试结果和详细信息
  /// @throws Exception 当通知发送失败时抛出异常
  Future<Map<String, dynamic>> showTestReminder() async {
    final Map<String, dynamic> result = {
      'success': false,
      'message': '',
      'details': <String>[],
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    try {
      debugPrint('=== 开始测试通知发送 ===');
      result['details'].add('开始测试通知发送');
      
      // 1. 检查初始化状态
      if (!_isInitialized) {
        debugPrint('通知服务未初始化，正在初始化...');
        result['details'].add('通知服务未初始化，正在初始化');
        await initialize();
        debugPrint('通知服务初始化完成');
        result['details'].add('通知服务初始化完成');
      } else {
        debugPrint('通知服务已初始化');
        result['details'].add('通知服务已初始化');
      }
      
      // 2. 检查通知权限
      debugPrint('检查通知权限...');
      result['details'].add('检查通知权限');
      final bool hasPermission = await hasPermissions();
      debugPrint('通知权限状态: ${hasPermission ? "已授予" : "未授予"}');
      result['details'].add('通知权限状态: ${hasPermission ? "已授予" : "未授予"}');
      
      if (!hasPermission) {
        debugPrint('⚠️ 通知权限未授予，尝试请求权限...');
        result['details'].add('通知权限未授予，尝试请求权限');
        final bool granted = await requestPermissions();
        debugPrint('权限请求结果: ${granted ? "已授予" : "被拒绝"}');
        result['details'].add('权限请求结果: ${granted ? "已授予" : "被拒绝"}');
        
        if (!granted) {
          result['success'] = false;
          result['message'] = '通知权限被拒绝，无法发送测试通知';
          result['details'].add('❌ 测试失败：通知权限被拒绝');
          debugPrint('❌ 测试失败：通知权限被拒绝');
          return result;
        }
      }
      
      // 3. 发送测试通知
      debugPrint('发送测试通知...');
      result['details'].add('发送测试通知');
      
      const int testNotificationId = 9999;
      const String testTitle = '测试提醒';
      const String testMessage = '这是一条测试提醒消息。如果您看到这条消息，说明提醒功能正常工作！';
      
      await showExerciseReminder(
        notificationId: testNotificationId,
        activityName: '测试运动',
        customMessage: testMessage,
      );
      
      debugPrint('✅ 测试通知发送成功');
      result['success'] = true;
      result['message'] = '测试通知发送成功！请检查您的通知栏。';
      result['details'].add('✅ 测试通知发送成功');
      result['details'].add('通知ID: $testNotificationId');
      result['details'].add('通知标题: $testTitle');
      result['details'].add('通知内容: $testMessage');
      
      // 4. 检查待处理通知
      try {
        final pendingNotifications = await getPendingNotifications();
        debugPrint('当前待处理通知数量: ${pendingNotifications.length}');
        result['details'].add('当前待处理通知数量: ${pendingNotifications.length}');
        
        for (final notification in pendingNotifications) {
          debugPrint('待处理通知: ID=${notification.id}, 标题=${notification.title}');
          result['details'].add('待处理通知: ID=${notification.id}, 标题=${notification.title}');
        }
      } catch (e) {
        debugPrint('获取待处理通知失败: $e');
        result['details'].add('获取待处理通知失败: $e');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ 测试通知发送失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      result['success'] = false;
      result['message'] = '测试通知发送失败: $e';
      result['details'].add('❌ 测试通知发送失败: $e');
      result['details'].add('错误堆栈: $stackTrace');
    }
    
    debugPrint('=== 测试通知发送完成 ===');
    result['details'].add('测试通知发送完成');
    return result;
  }

  /// Generate unique notification ID
  static int generateNotificationId(int userId, int activityTypeId) {
    return userId * 1000 + activityTypeId;
  }
}
