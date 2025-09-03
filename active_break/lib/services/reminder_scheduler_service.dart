import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:workmanager/workmanager.dart';
import '../models/reminder_and_tips.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'dart:io' show Platform;

class ReminderSchedulerService {
  static final ReminderSchedulerService _instance =
      ReminderSchedulerService._internal();
  factory ReminderSchedulerService() => _instance;
  ReminderSchedulerService._internal();

  static const String _reminderTaskName = 'exercise_reminder_task';
  static const String _reminderTaskTag = 'exercise_reminder';

  bool _isInitialized = false;

  /// Initialize background task scheduler
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    _isInitialized = true;
    debugPrint('Reminder scheduler service initialized');
  }

  /// Schedule background tasks for user's reminder settings
  Future<void> scheduleReminders(int userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Cancel previous tasks
    await cancelReminders(userId);

    // Register periodic check task with platform-specific optimizations
    final frequency = Platform.isIOS
        ? const Duration(minutes: 1) // iOS: 1分钟间隔用于调试
        : const Duration(minutes: 15); // Android: 15分钟最小间隔

    final initialDelay = Platform.isIOS
        ? const Duration(seconds: 10) // iOS: 更短的初始延迟
        : const Duration(seconds: 30); // Android: 30秒延迟

    await Workmanager().registerPeriodicTask(
      '${_reminderTaskName}_$userId',
      _reminderTaskName,
      frequency: frequency,
      initialDelay: initialDelay,
      inputData: {
        'userId': userId,
        'platform': Platform.operatingSystem,
        'isDebugMode': kDebugMode,
      },
      tag: _reminderTaskTag,
      constraints: Constraints(
        networkType: NetworkType.notRequired, // 不需要网络
        requiresBatteryNotLow: false, // 允许低电量时运行
        requiresCharging: false, // 允许未充电时运行
        requiresDeviceIdle: false, // 允许设备活跃时运行
        requiresStorageNotLow: false, // 允许存储空间不足时运行
      ),
    );

    debugPrint(
      'Registered periodic task with ${frequency.inMinutes}-minute frequency for ${Platform.operatingSystem}',
    );

    debugPrint('Scheduled reminder task for user $userId');
  }

  /// Cancel user's reminder tasks
  Future<void> cancelReminders(int userId) async {
    await Workmanager().cancelByUniqueName('${_reminderTaskName}_$userId');
    debugPrint('Cancelled reminder tasks for user $userId');
  }

  /// Cancel all reminder tasks
  Future<void> cancelAllReminders() async {
    await Workmanager().cancelByTag(_reminderTaskTag);
    debugPrint('Cancelled all reminder tasks');
  }

  /// Immediately check and trigger reminders (for testing)
  Future<void> checkAndTriggerReminders(int userId) async {
    await _checkReminders(userId);
  }

  /// Check reminder settings and trigger notifications
  static Future<void> _checkReminders(int userId) async {
    try {
      final databaseService = DatabaseService();

      // Get all enabled reminder settings for the user
      final reminders = await _getUserActiveReminders(databaseService, userId);

      if (reminders.isEmpty) {
        debugPrint('User $userId has no enabled reminder settings');
        return;
      }

      final now = DateTime.now();
      final notificationService = NotificationService();
      await notificationService.initialize();

      for (final reminder in reminders) {
        if (await _shouldTriggerReminder(reminder, now)) {
          // Get activity type information
          final activityType = await databaseService.getPhysicalActivityById(
            reminder.activityTypeId,
          );
          final activityName = activityType?.name ?? 'Exercise';

          // Generate notification ID
          final notificationId = NotificationService.generateNotificationId(
            userId,
            reminder.activityTypeId,
          );

          // Show reminder notification
          await notificationService.showExerciseReminder(
            notificationId: notificationId,
            activityName: activityName,
          );

          // Record reminder trigger history
          final db = await databaseService.database;
          await db.insert('reminder_logs', {
            'user_id': userId,
            'activity_type_id': reminder.activityTypeId,
            'triggered_at': now.millisecondsSinceEpoch,
          });

          debugPrint(
            'Triggered exercise reminder: $activityName (User: $userId)',
          );
        }
      }
    } catch (e) {
      debugPrint('Error occurred while checking reminders: $e');
    }
  }

  /// Get user's active reminder settings
  static Future<List<ReminderSetting>> _getUserActiveReminders(
    DatabaseService databaseService,
    int userId,
  ) async {
    final db = await databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_settings',
      where: 'user_id = ? AND enabled = ? AND deleted = ?',
      whereArgs: [userId, 1, 0],
    );

    return List.generate(maps.length, (i) {
      return ReminderSetting.fromMap(maps[i]);
    });
  }

  /// Determine whether reminder should be triggered
  /// @author Author
  /// @date Current date and time
  /// @param reminder 提醒设置
  /// @param now 当前时间
  /// @return Future<bool> 是否应该触发提醒
  static Future<bool> _shouldTriggerReminder(
    ReminderSetting reminder,
    DateTime now,
  ) async {
    debugPrint(
      '检查是否应该触发提醒 - 用户: ${reminder.userId}, 运动: ${reminder.activityTypeId}',
    );

    // 1. 检查是否在时间范围内
    final startTime = TimeOfDay(
      hour: reminder.startTime.hour,
      minute: reminder.startTime.minute,
    );
    final endTime = TimeOfDay(
      hour: reminder.endTime.hour,
      minute: reminder.endTime.minute,
    );
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    if (!_isTimeInRange(currentTime, startTime, endTime)) {
      debugPrint('当前时间不在提醒范围内');
      return false;
    }
    debugPrint('时间范围检查通过');

    // 2. 检查是否已经在最近触发过提醒
    if (await _hasRecentlyTriggered(reminder, now)) {
      debugPrint('最近已经触发过提醒，跳过');
      return false;
    }
    debugPrint('最近触发检查通过');

    // 3. 关键检查：用户是否在间隔时间内未进行相应运动
    final hasExercisedRecently = await _hasExercisedInInterval(reminder, now);
    if (hasExercisedRecently) {
      debugPrint('用户在间隔时间内已经进行了运动，不需要提醒');
      return false;
    }
    debugPrint('用户在间隔时间内未运动，需要发送提醒');

    return true;
  }

  /// 检查用户是否在间隔时间内进行了相应运动
  /// @author Author
  /// @date Current date and time
  /// @param reminder 提醒设置
  /// @param now 当前时间
  /// @return Future<bool> 是否在间隔时间内进行了运动
  static Future<bool> _hasExercisedInInterval(
    ReminderSetting reminder,
    DateTime now,
  ) async {
    try {
      final databaseService = DatabaseService();
      final db = await databaseService.database;

      // 计算间隔时间的开始时间
      final intervalStart = now.subtract(
        Duration(minutes: reminder.intervalValue),
      );

      debugPrint('检查运动记录 - 间隔: ${reminder.intervalValue}分钟');
      debugPrint(
        '检查时间范围: ${intervalStart.toIso8601String()} 到 ${now.toIso8601String()}',
      );

      // 查询用户在间隔时间内是否有相应运动记录
      final List<Map<String, dynamic>> results = await db.query(
        't_activi_record',
        where:
            'user_id = ? AND activity_type_id = ? AND begin_time >= ? AND begin_time <= ? AND deleted = ?',
        whereArgs: [
          reminder.userId,
          reminder.activityTypeId,
          intervalStart.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
          0, // 未删除的记录
        ],
        limit: 1,
      );

      final hasExercised = results.isNotEmpty;
      if (hasExercised) {
        final lastExercise = DateTime.fromMillisecondsSinceEpoch(
          results.first['begin_time'],
        );
        debugPrint('找到运动记录，开始时间: ${lastExercise.toIso8601String()}');
      } else {
        debugPrint('在间隔时间内未找到运动记录');
      }

      return hasExercised;
    } catch (e) {
      debugPrint('检查运动记录失败: $e');
      // 如果查询失败，假设用户没有运动，允许发送提醒
      return false;
    }
  }

  /// Check if current time is within specified range
  static bool _isTimeInRange(
    TimeOfDay current,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Time range within the same day
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Time range across days
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// Check if should trigger based on interval period
  /// @author Author
  /// @date Current date and time
  /// @param reminder Reminder setting
  /// @param now Current time
  /// @return bool Whether should trigger based on interval
  static bool _shouldTriggerByInterval(ReminderSetting reminder, DateTime now) {
    debugPrint(
      'Checking interval trigger for ${reminder.intervalValue} minutes',
    );

    // For minute-based intervals (5-1440 minutes)
    if (reminder.intervalValue > 0 && reminder.intervalValue < 1440) {
      // Calculate minutes since start time today
      final startTime = reminder.startTime;
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      debugPrint('Today start time: ${todayStart.toIso8601String()}');
      debugPrint('Current time: ${now.toIso8601String()}');

      // If current time is before start time today, don't trigger
      if (now.isBefore(todayStart)) {
        debugPrint('Current time is before start time, not triggering');
        return false;
      }

      // Calculate minutes elapsed since start time today
      final minutesElapsed = now.difference(todayStart).inMinutes;
      debugPrint('Minutes elapsed since start: $minutesElapsed');

      // For intervals, we want to trigger at regular intervals
      // For example, if interval is 5 minutes, trigger at 5, 10, 15, 20, etc.
      if (minutesElapsed < reminder.intervalValue) {
        debugPrint('Not enough time elapsed for first interval');
        return false;
      }

      // Check if we're at an interval boundary (with 2-minute tolerance)
      final intervalsPassed = minutesElapsed ~/ reminder.intervalValue;
      final nextIntervalTime = intervalsPassed * reminder.intervalValue;
      final timeSinceLastInterval = minutesElapsed - nextIntervalTime;

      debugPrint('Intervals passed: $intervalsPassed');
      debugPrint('Next interval time: $nextIntervalTime minutes');
      debugPrint('Time since last interval: $timeSinceLastInterval minutes');

      // Allow triggering if we're within 2 minutes of an interval boundary
      final shouldTrigger = timeSinceLastInterval <= 2;
      debugPrint('Should trigger: $shouldTrigger');

      return shouldTrigger;
    }

    // For day-based intervals, check based on days since creation
    final daysSinceCreated = now.difference(reminder.createdAt ?? now).inDays;

    // If week interval is set (in days), check if it satisfies the day interval
    if (reminder.intervalWeek > 0) {
      return daysSinceCreated % reminder.intervalWeek == 0;
    }

    // If no week interval is set, allow triggering every day by default
    return true;
  }

  /// Check if already triggered within recent interval time
  /// @author Author
  /// @date Current date and time
  /// @param reminder Reminder setting
  /// @param now Current time
  /// @return Future<bool> Whether recently triggered within interval
  static Future<bool> _hasRecentlyTriggered(
    ReminderSetting reminder,
    DateTime now,
  ) async {
    try {
      final databaseService = DatabaseService();
      final db = await databaseService.database;

      // Use a more reasonable check period - 80% of the interval to prevent too frequent triggers
      // but still allow some flexibility for background task timing
      final checkPeriodMinutes = (reminder.intervalValue * 0.8).round();
      final checkTime = now.subtract(Duration(minutes: checkPeriodMinutes));

      debugPrint(
        'Checking recent triggers for user ${reminder.userId}, activity ${reminder.activityTypeId}',
      );
      debugPrint(
        'Check period: $checkPeriodMinutes minutes, since: ${checkTime.toIso8601String()}',
      );

      // Query recent reminder records within the check period
      final List<Map<String, dynamic>> results = await db.query(
        'reminder_logs',
        where: 'user_id = ? AND activity_type_id = ? AND triggered_at > ?',
        whereArgs: [
          reminder.userId,
          reminder.activityTypeId,
          checkTime.millisecondsSinceEpoch,
        ],
        orderBy: 'triggered_at DESC',
        limit: 1,
      );

      final hasRecent = results.isNotEmpty;
      if (hasRecent) {
        final lastTrigger = DateTime.fromMillisecondsSinceEpoch(
          results.first['triggered_at'],
        );
        debugPrint('Found recent trigger at: ${lastTrigger.toIso8601String()}');
      } else {
        debugPrint('No recent triggers found');
      }

      return hasRecent;
    } catch (e) {
      debugPrint('Failed to check recent trigger records: $e');
      // If query fails, assume no recent trigger to allow reminder
      return false;
    }
  }
}

/// Background task callback function
/// @author Author
/// @date Current date and time
/// @return void
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final platform = inputData?['platform'] ?? 'unknown';
    final isDebugMode = inputData?['isDebugMode'] ?? false;

    debugPrint('=== 后台任务开始执行 ===');
    debugPrint('任务名称: $task');
    debugPrint('平台: $platform');
    debugPrint('调试模式: $isDebugMode');
    debugPrint('输入数据: $inputData');
    debugPrint('执行时间: ${DateTime.now().toIso8601String()}');

    try {
      switch (task) {
        case 'exercise_reminder_task':
          final userId = inputData?['userId'] as int?;
          if (userId != null) {
            debugPrint('开始检查用户 $userId 的提醒设置');

            // iOS 特定优化：更频繁的检查
            if (platform == 'ios') {
              debugPrint('iOS 平台：执行增强的提醒检查');
              await _performEnhancedReminderCheck(userId);
            } else {
              debugPrint('Android 平台：执行标准提醒检查');
              await ReminderSchedulerService._checkReminders(userId);
            }

            debugPrint('用户 $userId 的提醒检查完成');
          } else {
            debugPrint('错误：未提供用户ID');
            return Future.value(false);
          }
          break;
        default:
          debugPrint('未知的后台任务: $task');
          return Future.value(false);
      }

      debugPrint('=== 后台任务执行成功 ===');
      return Future.value(true);
    } catch (e, stackTrace) {
      debugPrint('=== 后台任务执行失败 ===');
      debugPrint('错误信息: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return Future.value(false);
    }
  });
}

/// iOS 增强的提醒检查
/// @author Author
/// @date Current date and time
/// @param userId 用户ID
/// @return Future<void>
Future<void> _performEnhancedReminderCheck(int userId) async {
  try {
    debugPrint('开始 iOS 增强提醒检查');

    // 执行标准提醒检查（已包含运动记录验证逻辑）
    await ReminderSchedulerService._checkReminders(userId);

    debugPrint('iOS 增强提醒检查完成');
  } catch (e) {
    debugPrint('iOS 增强提醒检查失败: $e');
  }
}
