/**
 * @Description: 通知功能测试工具类
 * @className: NotificationTest
 * @author 作者
 * @date 2024-12-25 当前时间
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2024
 * @version V1.0
 */

import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/reminder_scheduler_service.dart';
import '../services/database_service.dart';
import '../models/reminder_and_tips.dart';

/**
 * 通知功能测试工具类
 * 用于诊断和测试通知相关功能
 */
class NotificationTest {
  static final NotificationTest _instance = NotificationTest._internal();
  factory NotificationTest() => _instance;
  NotificationTest._internal();

  /**
   * 测试通知权限状态
   * @author 作者
   * @date 2024-12-25 当前时间
   * @return Future<bool> 是否有通知权限
   */
  Future<bool> testNotificationPermissions() async {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      final hasPermissions = await notificationService.hasPermissions();
      debugPrint('=== Notification Permission Test ===');
      debugPrint('Has notification permissions: $hasPermissions');
      
      if (!hasPermissions) {
        debugPrint('Requesting notification permissions...');
        final granted = await notificationService.requestPermissions();
        debugPrint('Permission request result: $granted');
        return granted;
      }
      
      return hasPermissions;
    } catch (e) {
      debugPrint('Error testing notification permissions: $e');
      return false;
    }
  }

  /**
   * 测试基本通知功能
   * @author 作者
   * @date 2024-12-25 当前时间
   * @return Future<void>
   */
  Future<void> testBasicNotification() async {
    try {
      debugPrint('=== Basic Notification Test ===');
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      await notificationService.showTestReminder();
      debugPrint('Test notification sent successfully');
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  /**
   * 测试提醒调度服务
   * @author 作者
   * @date 2024-12-25 当前时间
   * @param userId 用户ID
   * @return Future<void>
   */
  Future<void> testReminderScheduler(int userId) async {
    try {
      debugPrint('=== Reminder Scheduler Test ===');
      final schedulerService = ReminderSchedulerService();
      await schedulerService.initialize();
      
      // 立即检查并触发提醒
      await schedulerService.checkAndTriggerReminders(userId);
      debugPrint('Immediate reminder check completed for user $userId');
    } catch (e) {
      debugPrint('Error testing reminder scheduler: $e');
    }
  }

  /**
   * 检查用户的提醒设置
   * @author 作者
   * @date 2024-12-25 当前时间
   * @param userId 用户ID
   * @return Future<void>
   */
  Future<void> checkUserReminderSettings(int userId) async {
    try {
      debugPrint('=== User Reminder Settings Check ===');
      final databaseService = DatabaseService();
      final db = await databaseService.database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'reminder_settings',
        where: 'user_id = ? AND deleted = ?',
        whereArgs: [userId, 0],
      );
      
      debugPrint('Found ${maps.length} reminder settings for user $userId:');
      for (final map in maps) {
        final reminder = ReminderSetting.fromMap(map);
        debugPrint('  - Activity Type ID: ${reminder.activityTypeId}');
        debugPrint('  - Enabled: ${reminder.enabled}');
        debugPrint('  - Interval: ${reminder.intervalValue} minutes');
        debugPrint('  - Week Interval: ${reminder.intervalWeek} days');
        debugPrint('  - Start Time: ${reminder.startTime}');
        debugPrint('  - End Time: ${reminder.endTime}');
        debugPrint('  - Created At: ${reminder.createdAt}');
        debugPrint('  ---');
      }
    } catch (e) {
      debugPrint('Error checking user reminder settings: $e');
    }
  }

  /**
   * 检查提醒日志
   * @author 作者
   * @date 2024-12-25 当前时间
   * @param userId 用户ID
   * @return Future<void>
   */
  Future<void> checkReminderLogs(int userId) async {
    try {
      debugPrint('=== Reminder Logs Check ===');
      final databaseService = DatabaseService();
      final db = await databaseService.database;
      
      final List<Map<String, dynamic>> logs = await db.query(
        'reminder_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'triggered_at DESC',
        limit: 10,
      );
      
      debugPrint('Found ${logs.length} recent reminder logs for user $userId:');
      for (final log in logs) {
        final triggeredAt = DateTime.fromMillisecondsSinceEpoch(log['triggered_at']);
        debugPrint('  - Activity Type ID: ${log['activity_type_id']}');
        debugPrint('  - Triggered At: $triggeredAt');
        debugPrint('  ---');
      }
    } catch (e) {
      debugPrint('Error checking reminder logs: $e');
    }
  }

  /**
   * 运行完整的诊断测试
   * @author 作者
   * @date 2024-12-25 当前时间
   * @param userId 用户ID
   * @return Future<void>
   */
  Future<void> runFullDiagnostic(int userId) async {
    debugPrint('\n=== STARTING FULL NOTIFICATION DIAGNOSTIC ===\n');
    
    // 1. 测试通知权限
    await testNotificationPermissions();
    
    // 2. 检查用户提醒设置
    await checkUserReminderSettings(userId);
    
    // 3. 检查提醒日志
    await checkReminderLogs(userId);
    
    // 4. 测试基本通知
    await testBasicNotification();
    
    // 5. 测试提醒调度
    await testReminderScheduler(userId);
    
    debugPrint('\n=== DIAGNOSTIC COMPLETED ===\n');
  }
}