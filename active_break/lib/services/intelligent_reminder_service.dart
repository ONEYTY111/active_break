/**
 * 智能运动提醒服务
 * @Description: 基于用户运动记录的智能提醒系统，在设定时间范围内检查用户是否完成运动，如未完成则发送提醒
 * @author Author
 * @date Current date and time
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2025
 * @version V1.0
 */
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:workmanager/workmanager.dart';
import '../models/reminder_and_tips.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

/**
 * 智能运动提醒服务类
 * @Description: 提供基于运动记录的智能提醒功能，只在用户未完成运动时发送提醒
 * @author Author
 * @date Current date and time
 */
class IntelligentReminderService {
  static IntelligentReminderService? _instance;
  static const String _reminderTaskName = 'intelligent_exercise_reminder_task';
  static const String _reminderTaskTag = 'intelligent_exercise_reminder';

  bool _isInitialized = false;
  bool _isRunning = false;
  int? _currentUserId;

  /**
   * 获取单例实例
   * @author Author
   * @date Current date and time
   * @return IntelligentReminderService 服务实例
   */
  static IntelligentReminderService get instance {
    _instance ??= IntelligentReminderService._();
    return _instance!;
  }

  /**
   * 私有构造函数
   * @author Author
   * @date Current date and time
   */
  IntelligentReminderService._();

  /**
   * 启动智能运动提醒系统
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当提醒系统启动失败时抛出异常
   */
  Future<void> startReminderSystem(int userId) async {
    if (_isRunning && _currentUserId == userId) {
      debugPrint('智能运动提醒系统已在为用户 $userId 运行中');
      return;
    }

    try {
      debugPrint('=== 启动智能运动提醒系统 ===');
      debugPrint('用户ID: $userId');
      debugPrint('平台: ${Platform.operatingSystem}');

      // 停止之前的提醒系统
      if (_isRunning) {
        await stopReminderSystem();
      }

      // 初始化WorkManager
      if (!_isInitialized) {
        await Workmanager().initialize(
          _intelligentReminderCallbackDispatcher,
          isInDebugMode: kDebugMode,
        );
        _isInitialized = true;
        debugPrint('WorkManager 初始化成功');
      }

      // 取消之前的任务（iOS不支持cancelByTag）
      if (!Platform.isIOS) {
        await Workmanager().cancelByTag(_reminderTaskTag);
      } else {
        // iOS平台使用cancelAll替代
        await Workmanager().cancelAll();
        debugPrint('iOS平台：使用cancelAll取消所有后台任务');
      }

      // 获取用户的提醒设置
      final reminderSettings = await _getUserReminderSettings(userId);

      if (reminderSettings.isEmpty) {
        debugPrint('用户 $userId 没有启用的提醒设置');
        return;
      }

      debugPrint('找到 ${reminderSettings.length} 个启用的提醒设置');

      // 注册周期性检查任务
      final frequency = Platform.isIOS
          ? const Duration(minutes: 1) // iOS: 1分钟间隔用于精确检查
          : const Duration(minutes: 5); // Android: 5分钟间隔

      await Workmanager().registerPeriodicTask(
        '${_reminderTaskName}_$userId',
        _reminderTaskName,
        frequency: frequency,
        initialDelay: const Duration(seconds: 30),
        inputData: {
          'userId': userId,
          'platform': Platform.operatingSystem,
          'isDebugMode': kDebugMode,
        },
        tag: _reminderTaskTag,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      _currentUserId = userId;
      _isRunning = true;

      debugPrint('智能运动提醒系统启动成功，检查频率: ${frequency.inMinutes} 分钟');

      // 立即执行一次检查
      await _checkIntelligentReminders(userId);
    } catch (e, stackTrace) {
      debugPrint('启动智能运动提醒系统失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  /**
   * 停止智能运动提醒系统
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  Future<void> stopReminderSystem() async {
    if (!_isRunning) {
      debugPrint('智能运动提醒系统未在运行');
      return;
    }

    try {
      debugPrint('=== 停止智能运动提醒系统 ===');

      // 取消所有相关任务
      await Workmanager().cancelByTag(_reminderTaskTag);

      if (_currentUserId != null) {
        await Workmanager().cancelByUniqueName(
          '${_reminderTaskName}_$_currentUserId',
        );
      }

      _isRunning = false;
      _currentUserId = null;

      debugPrint('智能运动提醒系统已停止');
    } catch (e) {
      debugPrint('停止智能运动提醒系统时出错: $e');
    }
  }

  /**
   * 执行智能提醒检查（公共方法，供iOS后台任务调用）
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当检查过程中发生错误时抛出异常
   */
  Future<void> performReminderCheck(int userId) async {
    await _checkIntelligentReminders(userId);
  }

  /**
   * 获取用户的提醒设置
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<List<ReminderSetting>> 用户的提醒设置列表
   * @throws Exception 当数据库查询失败时抛出异常
   */
  Future<List<ReminderSetting>> _getUserReminderSettings(int userId) async {
    try {
      final databaseService = DatabaseService();
      final db = await databaseService.database;

      final List<Map<String, dynamic>> maps = await db.query(
        'reminder_settings',
        where: 'user_id = ? AND enabled = ? AND deleted = ?',
        whereArgs: [userId, 1, 0],
      );

      return List.generate(maps.length, (i) {
        return ReminderSetting.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('获取用户提醒设置失败: $e');
      return [];
    }
  }

  /**
   * 智能提醒检查逻辑
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当检查过程中发生错误时抛出异常
   */
  static Future<void> _checkIntelligentReminders(int userId) async {
    try {
      debugPrint('=== 开始智能提醒检查 ===');
      debugPrint('用户ID: $userId');
      debugPrint('检查时间: ${DateTime.now().toIso8601String()}');

      final databaseService = DatabaseService();

      // 获取用户的提醒设置
      final reminderSettings = await IntelligentReminderService.instance
          ._getUserReminderSettings(userId);

      if (reminderSettings.isEmpty) {
        debugPrint('用户 $userId 没有启用的提醒设置');
        return;
      }

      final now = DateTime.now();
      final notificationService = NotificationService();
      await notificationService.initialize();

      for (final reminder in reminderSettings) {
        await _checkSingleReminderSetting(
          reminder,
          now,
          databaseService,
          notificationService,
          userId,
        );
      }

      debugPrint('=== 智能提醒检查完成 ===');
    } catch (e, stackTrace) {
      debugPrint('智能提醒检查失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }
  }

  /**
   * 检查单个提醒设置
   * @author Author
   * @date Current date and time
   * @param reminder 提醒设置
   * @param now 当前时间
   * @param databaseService 数据库服务
   * @param notificationService 通知服务
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当检查过程中发生错误时抛出异常
   */
  static Future<void> _checkSingleReminderSetting(
    ReminderSetting reminder,
    DateTime now,
    DatabaseService databaseService,
    NotificationService notificationService,
    int userId,
  ) async {
    try {
      debugPrint('--- 检查提醒设置 ---');
      debugPrint('活动类型ID: ${reminder.activityTypeId}');
      debugPrint('间隔时间: ${reminder.intervalValue} 分钟');

      // 1. 检查是否在时间范围内
      if (!_isInTimeRange(reminder, now)) {
        debugPrint('当前时间不在提醒范围内，跳过');
        return;
      }

      // 2. 检查是否需要根据间隔发送提醒
      if (!_shouldCheckByInterval(reminder, now)) {
        debugPrint('当前时间不在间隔检查点，跳过');
        return;
      }

      // 3. 检查用户是否已经完成了该运动
      final hasCompletedExercise = await _hasUserCompletedExercise(
        databaseService,
        userId,
        reminder.activityTypeId,
        reminder.intervalValue,
        now,
      );

      if (hasCompletedExercise) {
        debugPrint('用户已在间隔时间内完成该运动，无需提醒');
        return;
      }

      // 4. 检查是否最近已经发送过提醒
      if (await _hasRecentlySentReminder(databaseService, reminder, now)) {
        debugPrint('最近已发送过提醒，避免重复发送');
        return;
      }

      // 5. 发送提醒通知
      await _sendIntelligentReminder(
        databaseService,
        notificationService,
        reminder,
        userId,
        now,
      );
    } catch (e) {
      debugPrint('检查单个提醒设置失败: $e');
    }
  }

  /**
   * 检查是否在时间范围内
   * @author Author
   * @date Current date and time
   * @param reminder 提醒设置
   * @param now 当前时间
   * @return bool 是否在时间范围内
   */
  static bool _isInTimeRange(ReminderSetting reminder, DateTime now) {
    final startTime = TimeOfDay(
      hour: reminder.startTime.hour,
      minute: reminder.startTime.minute,
    );
    final endTime = TimeOfDay(
      hour: reminder.endTime.hour,
      minute: reminder.endTime.minute,
    );
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes <= endMinutes) {
      // 时间范围在同一天内
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // 时间范围跨天
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /**
   * 检查是否应该根据间隔进行检查
   * @author Author
   * @date Current date and time
   * @param reminder 提醒设置
   * @param now 当前时间
   * @return bool 是否应该检查
   */
  static bool _shouldCheckByInterval(ReminderSetting reminder, DateTime now) {
    // 对于分钟级间隔（1-1440分钟）
    if (reminder.intervalValue > 0 && reminder.intervalValue < 1440) {
      final startTime = reminder.startTime;
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      // 如果当前时间在今天开始时间之前，不检查
      if (now.isBefore(todayStart)) {
        debugPrint('当前时间在开始时间之前，跳过检查');
        return false;
      }

      // 计算从开始时间到现在的分钟数
      final minutesElapsed = now.difference(todayStart).inMinutes;
      debugPrint(
        '从开始时间已过去 $minutesElapsed 分钟，间隔设置为 ${reminder.intervalValue} 分钟',
      );

      // 对于短间隔（<=5分钟），更宽松的检查策略
      if (reminder.intervalValue <= 5) {
        // 如果已经过了开始时间，就允许检查
        debugPrint('短间隔提醒（${reminder.intervalValue}分钟），允许检查');
        return true;
      }

      // 对于较长间隔，检查是否到了间隔检查点（允许3分钟的容差）
      final intervalsPassed = minutesElapsed ~/ reminder.intervalValue;
      final nextIntervalTime = intervalsPassed * reminder.intervalValue;
      final timeSinceLastInterval = minutesElapsed - nextIntervalTime;

      debugPrint(
        '间隔检查：已过间隔数=$intervalsPassed，距离上次间隔点=$timeSinceLastInterval分钟',
      );
      return timeSinceLastInterval <= 3;
    }

    // 对于天级间隔，每天检查一次
    return true;
  }

  /**
   * 检查用户是否已完成运动
   * @author Author
   * @date Current date and time
   * @param databaseService 数据库服务
   * @param userId 用户ID
   * @param activityTypeId 活动类型ID
   * @param intervalMinutes 间隔分钟数
   * @param now 当前时间
   * @return Future<bool> 是否已完成运动
   * @throws Exception 当数据库查询失败时抛出异常
   */
  static Future<bool> _hasUserCompletedExercise(
    DatabaseService databaseService,
    int userId,
    int activityTypeId,
    int intervalMinutes,
    DateTime now,
  ) async {
    try {
      final db = await databaseService.database;

      // 计算检查的时间范围（从当前时间往前推间隔时间）
      final checkStartTime = now.subtract(Duration(minutes: intervalMinutes));

      debugPrint(
        '检查运动记录时间范围: ${checkStartTime.toIso8601String()} 到 ${now.toIso8601String()}',
      );

      // 查询在间隔时间内是否有该类型的运动记录
      final List<Map<String, dynamic>> records = await db.query(
        't_activi_record',
        where:
            'user_id = ? AND activity_type_id = ? AND begin_time >= ? AND begin_time <= ? AND deleted = ?',
        whereArgs: [
          userId,
          activityTypeId,
          checkStartTime.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch,
          0, // 未删除的记录
        ],
        limit: 1,
      );

      final hasCompleted = records.isNotEmpty;
      debugPrint('用户在间隔时间内${hasCompleted ? "已完成" : "未完成"}该运动');

      return hasCompleted;
    } catch (e) {
      debugPrint('检查用户运动记录失败: $e');
      // 如果查询失败，假设用户未完成运动，确保发送提醒
      return false;
    }
  }

  /**
   * 检查是否最近已发送过提醒
   * @author Author
   * @date Current date and time
   * @param databaseService 数据库服务
   * @param reminder 提醒设置
   * @param now 当前时间
   * @return Future<bool> 是否最近已发送过提醒
   * @throws Exception 当数据库查询失败时抛出异常
   */
  static Future<bool> _hasRecentlySentReminder(
    DatabaseService databaseService,
    ReminderSetting reminder,
    DateTime now,
  ) async {
    try {
      final db = await databaseService.database;

      // 对于短间隔（≤5分钟），使用更短的防重复窗口以便测试
      // 对于长间隔，使用80%的间隔时间作为防重复窗口
      double checkRatio;
      if (reminder.intervalValue <= 5) {
        // 短间隔：使用50%的间隔时间，最少30秒
        checkRatio = 0.5;
        final minCheckSeconds = 30;
        final calculatedSeconds = (reminder.intervalValue * 60 * checkRatio)
            .round();
        final checkPeriodSeconds = calculatedSeconds < minCheckSeconds
            ? minCheckSeconds
            : calculatedSeconds;
        final checkTime = now.subtract(Duration(seconds: checkPeriodSeconds));

        debugPrint(
          '短间隔防重复检查：间隔=${reminder.intervalValue}分钟，检查窗口=${checkPeriodSeconds}秒',
        );

        final List<Map<String, dynamic>> results = await db.query(
          'reminder_logs',
          where: 'user_id = ? AND activity_type_id = ? AND triggered_at > ?',
          whereArgs: [
            reminder.userId,
            reminder.activityTypeId,
            checkTime.millisecondsSinceEpoch,
          ],
          limit: 1,
        );

        if (results.isNotEmpty) {
          final lastTriggerTime = DateTime.fromMillisecondsSinceEpoch(
            results.first['triggered_at'],
          );
          final timeSinceLastTrigger = now
              .difference(lastTriggerTime)
              .inSeconds;
          debugPrint(
            '上次提醒时间：${lastTriggerTime.toIso8601String()}，距今${timeSinceLastTrigger}秒',
          );
        }

        return results.isNotEmpty;
      } else {
        // 长间隔：使用80%的间隔时间
        checkRatio = 0.8;
        final checkPeriodMinutes = (reminder.intervalValue * checkRatio)
            .round();
        final checkTime = now.subtract(Duration(minutes: checkPeriodMinutes));

        debugPrint(
          '长间隔防重复检查：间隔=${reminder.intervalValue}分钟，检查窗口=${checkPeriodMinutes}分钟',
        );

        final List<Map<String, dynamic>> results = await db.query(
          'reminder_logs',
          where: 'user_id = ? AND activity_type_id = ? AND triggered_at > ?',
          whereArgs: [
            reminder.userId,
            reminder.activityTypeId,
            checkTime.millisecondsSinceEpoch,
          ],
          limit: 1,
        );

        return results.isNotEmpty;
      }
    } catch (e) {
      debugPrint('检查最近提醒记录失败: $e');
      // 如果查询失败，假设没有发送过，允许发送提醒
      return false;
    }
  }

  /**
   * 发送智能提醒
   * @author Author
   * @date Current date and time
   * @param databaseService 数据库服务
   * @param notificationService 通知服务
   * @param reminder 提醒设置
   * @param userId 用户ID
   * @param now 当前时间
   * @return Future<void>
   * @throws Exception 当发送提醒失败时抛出异常
   */
  static Future<void> _sendIntelligentReminder(
    DatabaseService databaseService,
    NotificationService notificationService,
    ReminderSetting reminder,
    int userId,
    DateTime now,
  ) async {
    try {
      // 获取活动类型信息
      final activityType = await databaseService.getPhysicalActivityById(
        reminder.activityTypeId,
      );
      final activityName = activityType?.name ?? '运动';

      // 生成通知ID
      final notificationId = NotificationService.generateNotificationId(
        userId,
        reminder.activityTypeId,
      );

      // 发送提醒通知
      await notificationService.showExerciseReminder(
        notificationId: notificationId,
        activityName: activityName,
      );

      // 记录提醒发送历史
      final db = await databaseService.database;
      await db.insert('reminder_logs', {
        'user_id': userId,
        'activity_type_id': reminder.activityTypeId,
        'triggered_at': now.millisecondsSinceEpoch,
      });

      debugPrint('✅ 智能提醒已发送: $activityName (用户: $userId)');
    } catch (e) {
      debugPrint('发送智能提醒失败: $e');
    }
  }

  /**
   * 获取运行状态
   * @author Author
   * @date Current date and time
   * @return bool 是否正在运行
   */
  bool get isRunning => _isRunning;

  /**
   * 获取当前用户ID
   * @author Author
   * @date Current date and time
   * @return int? 当前用户ID
   */
  int? get currentUserId => _currentUserId;
}

/**
 * 智能提醒后台任务回调函数
 * @author Author
 * @date Current date and time
 * @return void
 */
@pragma('vm:entry-point')
void _intelligentReminderCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final platform = inputData?['platform'] ?? 'unknown';
    final isDebugMode = inputData?['isDebugMode'] ?? false;

    debugPrint('=== 智能提醒后台任务开始执行 ===');
    debugPrint('任务名称: $task');
    debugPrint('平台: $platform');
    debugPrint('调试模式: $isDebugMode');
    debugPrint('输入数据: $inputData');
    debugPrint('执行时间: ${DateTime.now().toIso8601String()}');

    try {
      switch (task) {
        case 'intelligent_exercise_reminder_task':
          final userId = inputData?['userId'] as int?;
          if (userId != null) {
            debugPrint('开始智能提醒检查，用户ID: $userId');
            await IntelligentReminderService._checkIntelligentReminders(userId);
            debugPrint('智能提醒检查完成');
          } else {
            debugPrint('错误：未提供用户ID');
            return Future.value(false);
          }
          break;
        default:
          debugPrint('未知的后台任务: $task');
          return Future.value(false);
      }

      debugPrint('=== 智能提醒后台任务执行成功 ===');
      return Future.value(true);
    } catch (e, stackTrace) {
      debugPrint('=== 智能提醒后台任务执行失败 ===');
      debugPrint('错误信息: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return Future.value(false);
    }
  });
}
