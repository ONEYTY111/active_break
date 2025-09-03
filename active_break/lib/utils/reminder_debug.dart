/**
 * 提醒功能调试工具类
 * @Description: 用于调试和诊断15分钟提醒功能的各个环节
 * @className: ReminderDebugger
 * @author Author
 * @date Current date and time
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2024
 * @version V1.0
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../services/database_service.dart';
import '../services/reminder_scheduler_service.dart';
import '../services/notification_service.dart';
import '../models/reminder_and_tips.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';

class ReminderDebugger {
  static final DatabaseService _databaseService = DatabaseService();
  static final ReminderSchedulerService _schedulerService = ReminderSchedulerService();
  static final NotificationService _notificationService = NotificationService();

  /**
   * 全面诊断提醒功能
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> fullDiagnosis(int userId) async {
    debugPrint('=== 开始全面诊断提醒功能 ===');
    debugPrint('用户ID: $userId');
    debugPrint('当前时间: ${DateTime.now()}');
    debugPrint('');

    // 1. 检查通知权限
    await _checkNotificationPermissions();
    debugPrint('');

    // 2. 检查数据库中的提醒设置
    await _checkReminderSettings(userId);
    debugPrint('');

    // 3. 检查后台任务状态
    await _checkBackgroundTasks();
    debugPrint('');

    // 4. 检查提醒触发逻辑
    await _checkReminderTriggerLogic(userId);
    debugPrint('');

    // 5. 检查提醒历史记录
    await _checkReminderLogs(userId);
    debugPrint('');

    // 6. 测试通知功能
    await _testNotificationFunction();
    debugPrint('');

    debugPrint('=== 全面诊断完成 ===');
  }

  /**
   * 检查通知权限
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  static Future<void> _checkNotificationPermissions() async {
    debugPrint('--- 检查通知权限 ---');
    
    try {
      final notificationStatus = await Permission.notification.status;
      debugPrint('通知权限状态: $notificationStatus');
      
      if (notificationStatus.isDenied) {
        debugPrint('⚠️ 通知权限被拒绝，这可能是提醒不工作的原因');
        final result = await Permission.notification.request();
        debugPrint('请求权限结果: $result');
      } else if (notificationStatus.isGranted) {
        debugPrint('✅ 通知权限已授予');
      }
      
      // 检查后台应用刷新权限（iOS）
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final backgroundStatus = await Permission.backgroundRefresh.status;
        debugPrint('后台刷新权限状态: $backgroundStatus');
      }
    } catch (e) {
      debugPrint('❌ 检查权限时出错: $e');
    }
  }

  /**
   * 检查数据库中的提醒设置
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> _checkReminderSettings(int userId) async {
    debugPrint('--- 检查数据库中的提醒设置 ---');
    
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'reminder_settings',
        where: 'user_id = ? AND deleted = ?',
        whereArgs: [userId, 0],
      );
      
      debugPrint('找到 ${maps.length} 条提醒设置记录:');
      
      if (maps.isEmpty) {
        debugPrint('❌ 没有找到任何提醒设置，这是提醒不工作的原因');
        return;
      }
      
      for (int i = 0; i < maps.length; i++) {
        final map = maps[i];
        final reminder = ReminderSetting.fromMap(map);
        debugPrint('  设置 ${i + 1}:');
        debugPrint('    - 活动类型ID: ${reminder.activityTypeId}');
        debugPrint('    - 是否启用: ${reminder.enabled ? "是" : "否"}');
        debugPrint('    - 间隔时间: ${reminder.intervalValue} 分钟');
        debugPrint('    - 开始时间: ${reminder.startTime.hour.toString().padLeft(2, '0')}:${reminder.startTime.minute.toString().padLeft(2, '0')}');
        debugPrint('    - 结束时间: ${reminder.endTime.hour.toString().padLeft(2, '0')}:${reminder.endTime.minute.toString().padLeft(2, '0')}');
        debugPrint('    - 创建时间: ${reminder.createdAt}');
        debugPrint('    - 更新时间: ${reminder.updatedAt}');
        
        // 检查时间范围是否合理
        final now = DateTime.now();
        final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
        final startTime = TimeOfDay(hour: reminder.startTime.hour, minute: reminder.startTime.minute);
        final endTime = TimeOfDay(hour: reminder.endTime.hour, minute: reminder.endTime.minute);
        
        final isInTimeRange = _isTimeInRange(currentTime, startTime, endTime);
        debugPrint('    - 当前是否在时间范围内: ${isInTimeRange ? "是" : "否"}');
        
        if (!reminder.enabled) {
          debugPrint('    ⚠️ 此提醒设置未启用');
        }
        
        debugPrint('');
      }
    } catch (e) {
      debugPrint('❌ 检查提醒设置时出错: $e');
    }
  }

  /**
   * 检查后台任务状态
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  static Future<void> _checkBackgroundTasks() async {
    debugPrint('--- 检查后台任务状态 ---');
    
    try {
      // 初始化调度服务
      await _schedulerService.initialize();
      debugPrint('✅ 提醒调度服务已初始化');
      
      // 注意：Workmanager 没有提供直接查询已注册任务的API
      // 我们只能通过日志来判断任务是否正确注册
      debugPrint('📝 后台任务注册状态无法直接查询，请查看日志确认');
      debugPrint('   如果看到 "Scheduled reminder task for user X" 说明任务已注册');
      
    } catch (e) {
      debugPrint('❌ 检查后台任务时出错: $e');
    }
  }

  /**
   * 检查提醒触发逻辑
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> _checkReminderTriggerLogic(int userId) async {
    debugPrint('--- 检查提醒触发逻辑 ---');
    
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'reminder_settings',
        where: 'user_id = ? AND enabled = ? AND deleted = ?',
        whereArgs: [userId, 1, 0],
      );
      
      if (maps.isEmpty) {
        debugPrint('❌ 没有启用的提醒设置');
        return;
      }
      
      final now = DateTime.now();
      debugPrint('当前时间: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
      
      for (final map in maps) {
        final reminder = ReminderSetting.fromMap(map);
        debugPrint('\n检查活动类型 ${reminder.activityTypeId} 的触发条件:');
        
        // 1. 检查时间范围
        final startTime = TimeOfDay(hour: reminder.startTime.hour, minute: reminder.startTime.minute);
        final endTime = TimeOfDay(hour: reminder.endTime.hour, minute: reminder.endTime.minute);
        final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
        
        final isInTimeRange = _isTimeInRange(currentTime, startTime, endTime);
        debugPrint('  1. 时间范围检查: ${isInTimeRange ? "✅ 通过" : "❌ 不在范围内"}');
        debugPrint('     设置范围: ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}');
        debugPrint('     当前时间: ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}');
        
        // 2. 检查间隔逻辑
        final shouldTriggerByInterval = _shouldTriggerByInterval(reminder, now);
        debugPrint('  2. 间隔逻辑检查: ${shouldTriggerByInterval ? "✅ 通过" : "❌ 不满足"}');
        debugPrint('     间隔设置: ${reminder.intervalValue} 分钟');
        
        // 3. 检查最近触发记录
        final hasRecentlyTriggered = await _hasRecentlyTriggered(reminder, now);
        debugPrint('  3. 最近触发检查: ${hasRecentlyTriggered ? "❌ 最近已触发" : "✅ 可以触发"}');
        
        // 综合判断
        final shouldTrigger = isInTimeRange && shouldTriggerByInterval && !hasRecentlyTriggered;
        debugPrint('  🎯 综合判断: ${shouldTrigger ? "✅ 应该触发提醒" : "❌ 不应该触发"}');
      }
    } catch (e) {
      debugPrint('❌ 检查触发逻辑时出错: $e');
    }
  }

  /**
   * 检查提醒历史记录
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> _checkReminderLogs(int userId) async {
    debugPrint('--- 检查提醒历史记录 ---');
    
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> logs = await db.query(
        'reminder_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'triggered_at DESC',
        limit: 10,
      );
      
      debugPrint('最近 ${logs.length} 条提醒记录:');
      
      if (logs.isEmpty) {
        debugPrint('❌ 没有找到任何提醒触发记录');
        debugPrint('   这表明提醒功能从未成功触发过');
        return;
      }
      
      for (int i = 0; i < logs.length; i++) {
        final log = logs[i];
        final triggeredAt = DateTime.fromMillisecondsSinceEpoch(log['triggered_at']);
        debugPrint('  ${i + 1}. 活动类型ID: ${log['activity_type_id']}, 触发时间: $triggeredAt');
      }
      
      // 检查最近15分钟内是否有触发记录
      final recentLogs = logs.where((log) {
        final triggeredAt = DateTime.fromMillisecondsSinceEpoch(log['triggered_at']);
        return DateTime.now().difference(triggeredAt).inMinutes <= 15;
      }).toList();
      
      if (recentLogs.isNotEmpty) {
        debugPrint('✅ 最近15分钟内有 ${recentLogs.length} 条触发记录');
      } else {
        debugPrint('⚠️ 最近15分钟内没有触发记录');
      }
    } catch (e) {
      debugPrint('❌ 检查提醒记录时出错: $e');
    }
  }

  /**
   * 测试通知功能
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  static Future<void> _testNotificationFunction() async {
    debugPrint('--- 测试通知功能 ---');
    
    try {
      await _notificationService.initialize();
      debugPrint('✅ 通知服务已初始化');
      
      // 发送测试通知
      await _notificationService.showTestReminder();
      debugPrint('✅ 测试通知已发送');
      debugPrint('   请检查设备是否收到通知');
      
    } catch (e) {
      debugPrint('❌ 测试通知功能时出错: $e');
    }
  }

  /**
   * 强制触发提醒检查（用于测试）
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> forceTriggerReminderCheck(int userId) async {
    debugPrint('=== 强制触发提醒检查 ===');
    
    try {
      await _schedulerService.checkAndTriggerReminders(userId);
      debugPrint('✅ 强制提醒检查已执行');
      
      // 等待一下，然后检查是否有新的日志记录
      await Future.delayed(const Duration(seconds: 2));
      await _checkReminderLogs(userId);
      
    } catch (e) {
      debugPrint('❌ 强制触发提醒检查时出错: $e');
    }
  }

  /**
   * 重新调度提醒任务
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> rescheduleReminders(int userId) async {
    debugPrint('=== 重新调度提醒任务 ===');
    
    try {
      // 取消现有任务
      await _schedulerService.cancelReminders(userId);
      debugPrint('✅ 已取消现有提醒任务');
      
      // 重新调度
      await _schedulerService.scheduleReminders(userId);
      debugPrint('✅ 已重新调度提醒任务');
      
    } catch (e) {
      debugPrint('❌ 重新调度提醒任务时出错: $e');
    }
  }

  // 辅助方法
  
  /**
   * 检查时间是否在指定范围内
   * @author Author
   * @date Current date and time
   * @param current 当前时间
   * @param start 开始时间
   * @param end 结束时间
   * @return bool 是否在范围内
   */
  static bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
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

  /**
   * 检查是否应该根据间隔触发
   * @author Author
   * @date Current date and time
   * @param reminder 提醒设置
   * @param now 当前时间
   * @return bool 是否应该触发
   */
  static bool _shouldTriggerByInterval(ReminderSetting reminder, DateTime now) {
    // 对于分钟级间隔（如15分钟），总是允许触发
    // 实际的间隔检查在 _hasRecentlyTriggered 方法中处理
    if (reminder.intervalValue > 0 && reminder.intervalValue < 1440) { // 小于24小时
      return true;
    }
    
    // 对于天级间隔，检查自创建以来的天数
    final daysSinceCreated = now.difference(reminder.createdAt ?? now).inDays;
    
    // 如果设置了周间隔（以天为单位），检查是否满足天间隔
    if (reminder.intervalWeek > 0) {
      return daysSinceCreated % reminder.intervalWeek == 0;
    }
    
    // 如果没有设置周间隔，默认每天都允许触发
    return true;
  }

  /**
   * 检查最近是否已触发
   * @author Author
   * @date Current date and time
   * @param reminder 提醒设置
   * @param now 当前时间
   * @return Future<bool> 最近是否已触发
   */
  static Future<bool> _hasRecentlyTriggered(ReminderSetting reminder, DateTime now) async {
    try {
      final db = await _databaseService.database;
      
      // 查询间隔时间内的最近提醒记录
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
      debugPrint('检查最近触发记录失败: $e');
      // 如果查询失败，假设没有最近触发以允许提醒
      return false;
    }
  }
}