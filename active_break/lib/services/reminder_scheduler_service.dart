import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:isolate';
import 'dart:ui';
import '../models/reminder_and_tips.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/physical_activity.dart';

class ReminderSchedulerService {
  static final ReminderSchedulerService _instance = ReminderSchedulerService._internal();
  factory ReminderSchedulerService() => _instance;
  ReminderSchedulerService._internal();

  static const String _reminderTaskName = 'exercise_reminder_task';
  static const String _reminderTaskTag = 'exercise_reminder';
  
  bool _isInitialized = false;

  /// 初始化后台任务调度器
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    _isInitialized = true;
    debugPrint('提醒调度服务初始化完成');
  }

  /// 为用户的提醒设置安排后台任务
  Future<void> scheduleReminders(int userId) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 取消之前的任务
    await cancelReminders(userId);

    // 注册周期性检查任务
    await Workmanager().registerPeriodicTask(
      '${_reminderTaskName}_$userId',
      _reminderTaskName,
      frequency: const Duration(minutes: 15), // 每15分钟检查一次
      initialDelay: const Duration(minutes: 1), // 1分钟后开始
      inputData: {
        'userId': userId,
      },
      tag: _reminderTaskTag,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );

    debugPrint('为用户 $userId 安排提醒任务');
  }

  /// 取消用户的提醒任务
  Future<void> cancelReminders(int userId) async {
    await Workmanager().cancelByUniqueName('${_reminderTaskName}_$userId');
    debugPrint('取消用户 $userId 的提醒任务');
  }

  /// 取消所有提醒任务
  Future<void> cancelAllReminders() async {
    await Workmanager().cancelByTag(_reminderTaskTag);
    debugPrint('取消所有提醒任务');
  }

  /// 立即检查并触发提醒（用于测试）
  Future<void> checkAndTriggerReminders(int userId) async {
    await _checkReminders(userId);
  }

  /// 检查提醒设置并触发通知
  static Future<void> _checkReminders(int userId) async {
    try {
      final databaseService = DatabaseService();

      // 获取用户的所有启用的提醒设置
      final reminders = await _getUserActiveReminders(databaseService, userId);
      
      if (reminders.isEmpty) {
        debugPrint('用户 $userId 没有启用的提醒设置');
        return;
      }

      final now = DateTime.now();
      final notificationService = NotificationService();
      await notificationService.initialize();

      for (final reminder in reminders) {
        if (await _shouldTriggerReminder(reminder, now)) {
          // 获取运动类型信息
          final activityType = await databaseService.getPhysicalActivityById(reminder.activityTypeId);
          final activityName = activityType?.name ?? '运动';

          // 生成通知ID
          final notificationId = NotificationService.generateNotificationId(
            userId, 
            reminder.activityTypeId,
          );

          // 显示提醒通知
          await notificationService.showExerciseReminder(
            notificationId: notificationId,
            activityName: activityName,
          );

          debugPrint('触发运动提醒: $activityName (用户: $userId)');
        }
      }
    } catch (e) {
      debugPrint('检查提醒时发生错误: $e');
    }
  }

  /// 获取用户的活跃提醒设置
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



  /// 判断是否应该触发提醒
  static Future<bool> _shouldTriggerReminder(
    ReminderSetting reminder, 
    DateTime now,
  ) async {
    // 检查是否在时间范围内
    final startTime = TimeOfDay(
      hour: reminder.startTime.hour,
      minute: reminder.startTime.minute,
    );
    final endTime = TimeOfDay(
      hour: reminder.endTime.hour,
      minute: reminder.endTime.minute,
    );
    final currentTime = TimeOfDay(
      hour: now.hour,
      minute: now.minute,
    );

    if (!_isTimeInRange(currentTime, startTime, endTime)) {
      return false;
    }

    // 检查间隔周期
    if (!_shouldTriggerByInterval(reminder, now)) {
      return false;
    }

    // 检查是否已经在最近的间隔时间内触发过
    if (await _hasRecentlyTriggered(reminder, now)) {
      return false;
    }

    return true;
  }

  /// 检查当前时间是否在指定范围内
  static bool _isTimeInRange(
    TimeOfDay current, 
    TimeOfDay start, 
    TimeOfDay end,
  ) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // 同一天内的时间范围
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 跨天的时间范围
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// 检查是否应该根据间隔周期触发
  static bool _shouldTriggerByInterval(
    ReminderSetting reminder, 
    DateTime now,
  ) {
    // 根据间隔周期检查
    final daysSinceEpoch = now.difference(DateTime(1970, 1, 1)).inDays;
    return daysSinceEpoch % reminder.intervalWeek == 0;
  }

  /// 检查是否在最近的间隔时间内已经触发过
  static Future<bool> _hasRecentlyTriggered(
    ReminderSetting reminder, 
    DateTime now,
  ) async {
    // 这里可以实现更复杂的逻辑，比如记录最后触发时间
    // 暂时简单实现：检查当前时间是否是间隔的倍数
    final minutesSinceStart = now.hour * 60 + now.minute;
    final startMinutes = reminder.startTime.hour * 60 + reminder.startTime.minute;
    final elapsedMinutes = minutesSinceStart - startMinutes;
    
    if (elapsedMinutes < 0) {
      return false; // 还没到开始时间
    }
    
    return elapsedMinutes % reminder.intervalValue == 0;
  }
}

/// 后台任务回调函数
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('执行后台任务: $task');
    
    try {
      switch (task) {
        case 'exercise_reminder_task':
          final userId = inputData?['userId'] as int?;
          if (userId != null) {
            await ReminderSchedulerService._checkReminders(userId);
          }
          break;
        default:
          debugPrint('未知的后台任务: $task');
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('后台任务执行失败: $e');
      return Future.value(false);
    }
  });
}

/// 时间辅助类
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}