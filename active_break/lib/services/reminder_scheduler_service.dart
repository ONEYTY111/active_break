import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:isolate';
import 'dart:ui';
import '../models/reminder_and_tips.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/physical_activity.dart';

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

    // Register periodic check task
    await Workmanager().registerPeriodicTask(
      '${_reminderTaskName}_$userId',
      _reminderTaskName,
      frequency: const Duration(minutes: 15), // Check every 15 minutes
      initialDelay: const Duration(minutes: 1), // Start after 1 minute
      inputData: {'userId': userId},
      tag: _reminderTaskTag,
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
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

          debugPrint('Triggered exercise reminder: $activityName (User: $userId)');
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
  static Future<bool> _shouldTriggerReminder(
    ReminderSetting reminder,
    DateTime now,
  ) async {
    // Check if within time range
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
      return false;
    }

    // Check interval period
    if (!_shouldTriggerByInterval(reminder, now)) {
      return false;
    }

    // Check if already triggered within recent interval
    if (await _hasRecentlyTriggered(reminder, now)) {
      return false;
    }

    return true;
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
  /// @author 作者
  /// @date 2024-12-25 当前时间
  /// @param reminder 提醒设置
  /// @param now 当前时间
  /// @return bool 是否应该根据间隔触发
  static bool _shouldTriggerByInterval(ReminderSetting reminder, DateTime now) {
    // 检查基于天数的间隔周期
    final daysSinceCreated = now.difference(reminder.createdAt ?? now).inDays;
    
    // 如果设置了周间隔（天数），检查是否满足天数间隔
    if (reminder.intervalWeek > 0) {
      return daysSinceCreated % reminder.intervalWeek == 0;
    }
    
    // 如果没有设置周间隔，默认每天都可以触发
    return true;
  }

  /// Check if already triggered within recent interval time
  static Future<bool> _hasRecentlyTriggered(
    ReminderSetting reminder,
    DateTime now,
  ) async {
    try {
      final databaseService = DatabaseService();
      final db = await databaseService.database;
      
      // Query recent reminder records
      final List<Map<String, dynamic>> results = await db.query(
        'reminder_logs',
        where: 'user_id = ? AND activity_type_id = ? AND triggered_at > ?',
        whereArgs: [
          reminder.userId,
          reminder.activityTypeId,
          now.subtract(Duration(minutes: reminder.intervalValue)).millisecondsSinceEpoch,
        ],
        orderBy: 'triggered_at DESC',
        limit: 1,
      );
      
      return results.isNotEmpty;
    } catch (e) {
      debugPrint('Failed to check recent trigger records: $e');
      // If query fails, use simple time interval check
      final minutesSinceStart = now.hour * 60 + now.minute;
      final startMinutes = reminder.startTime.hour * 60 + reminder.startTime.minute;
      final elapsedMinutes = minutesSinceStart - startMinutes;
      
      if (elapsedMinutes < 0) {
        return false; // Not yet start time
      }
      
      return elapsedMinutes % reminder.intervalValue != 0;
    }
  }
}

/// Background task callback function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Executing background task: $task');

    try {
      switch (task) {
        case 'exercise_reminder_task':
          final userId = inputData?['userId'] as int?;
          if (userId != null) {
            await ReminderSchedulerService._checkReminders(userId);
          }
          break;
        default:
          debugPrint('Unknown background task: $task');
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('Background task execution failed: $e');
      return Future.value(false);
    }
  });
}

/// Time helper class
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
