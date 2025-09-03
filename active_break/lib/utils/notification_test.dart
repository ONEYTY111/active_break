/**
 * @Description: Notification test utility class
 * @className: NotificationTest
 * @author Author
 * @date Current date and time
 * @company: Xi'an Boda Software Co., Ltd.
 * @copyright: Copyright (c) 2024
 * @version V1.0
 */

import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/reminder_scheduler_service.dart';
import '../services/database_service.dart';
import '../models/reminder_and_tips.dart';

/**
 * Notification test utility class
 * Used for diagnosing and testing notification-related functions
 */
class NotificationTest {
  static final NotificationTest _instance = NotificationTest._internal();
  factory NotificationTest() => _instance;
  NotificationTest._internal();

  /**
   * Test notification permission status
   * @author Author
   * @date Current date and time
   * @return Future<bool> Whether has notification permission
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
   * Test basic notification functionality
   * @author Author
   * @date Current date and time
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
   * Test reminder scheduler service
   * @author Author
   * @date Current date and time
   * @param userId User ID
   * @param activityTypeId Activity type ID
   * @return Future<void>
   */
  Future<void> testReminderScheduler(int userId, int activityTypeId) async {
    try {
      debugPrint('=== Testing Reminder Scheduler ===');
      
      // 1. Initialize reminder scheduler service
      final schedulerService = ReminderSchedulerService();
      await schedulerService.initialize();
      debugPrint('Reminder scheduler service initialized');
      
      // 2. Check current reminder settings
      final databaseService = DatabaseService();
      final db = await databaseService.database;
      final reminders = await db.query(
        'reminder_settings',
        where: 'user_id = ? AND enabled = ? AND deleted = ?',
        whereArgs: [userId, 1, 0],
      );
      
      debugPrint('Found ${reminders.length} enabled reminder settings:');
      for (final reminder in reminders) {
        debugPrint('  - Activity Type ID: ${reminder['activity_type_id']}');
        debugPrint('  - Interval Value: ${reminder['interval_value']} minutes');
        debugPrint('  - Start Time: ${reminder['start_time']}');
        debugPrint('  - End Time: ${reminder['end_time']}');
        debugPrint('  - Created At: ${reminder['created_at']}');
      }
      
      // 3. Schedule reminder tasks
      await schedulerService.scheduleReminders(userId);
      debugPrint('Reminder tasks scheduled for user $userId');
      
      // 4. Immediately check and trigger reminders (for testing)
      await schedulerService.checkAndTriggerReminders(userId);
      debugPrint('Immediate reminder check completed');
      
      // 5. Check if any reminder logs were created
      await Future.delayed(const Duration(seconds: 2));
      await checkReminderLogs(userId);
      
    } catch (e) {
      debugPrint('Error testing reminder scheduler: $e');
    }
  }

  /**
   * Check user reminder settings
   * @author Author
   * @date Current date and time
   * @param userId User ID
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
   * Check reminder logs
   * @author Author
   * @date Current date and time
   * @param userId User ID
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
   * Run comprehensive diagnostic test
   * @author Author
   * @date Current date and time
   * @param userId User ID
   * @return Future<void>
   */
  Future<void> runFullDiagnostic(int userId) async {
    debugPrint('\n=== STARTING FULL NOTIFICATION DIAGNOSTIC ===\n');
    
    // 1. Test notification permissions
      await testNotificationPermissions();
      
      // 2. Check user reminder settings
      await checkUserReminderSettings(userId);
      
      // 3. Check reminder logs
      await checkReminderLogs(userId);
      
      // 4. Test basic notification
      await testBasicNotification();
      
      // 5. Test reminder scheduler
      await testReminderScheduler(userId, 1); // Use activity type ID 1 for testing
    
    debugPrint('\n=== DIAGNOSTIC COMPLETED ===\n');
  }
}