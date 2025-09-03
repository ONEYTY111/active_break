/**
 * 简单定时提醒服务
 * @Description: 提供简单的定时提醒功能，每分钟发送一次固定内容的提醒
 * @className: SimpleReminderService
 * @author 助手
 * @date 2025-01-02
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2025
 * @version V1.0
 */

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

/**
 * 简单定时提醒服务类
 * 提供每分钟发送一次固定内容提醒的功能
 */
class SimpleReminderService {
  static SimpleReminderService? _instance;
  static SimpleReminderService get instance {
    _instance ??= SimpleReminderService._internal();
    return _instance!;
  }

  SimpleReminderService._internal();

  final NotificationService _notificationService = NotificationService();
  bool _isRunning = false;
  int _notificationCounter = 1;
  static const int _reminderIntervalSeconds = 15;
  static const int _maxScheduledNotifications = 100; // 最多预调度100个通知

  /**
   * 启动定时提醒
   * @author 助手
   * @date 2025-01-02
   * @return Future<void>
   * @throws Exception 当启动失败时抛出异常
   */
  Future<void> startReminder() async {
    debugPrint('🚀 SimpleReminderService: startReminder() called');
    
    if (_isRunning) {
      debugPrint('⚠️ Simple reminder service is already running');
      return;
    }

    try {
      debugPrint('📱 Initializing notification service...');
      // 初始化通知服务
      await _notificationService.initialize();
      debugPrint('✅ Notification service initialized successfully');
      
      // 检查并请求通知权限
      debugPrint('🔐 Checking notification permissions...');
      final hasPermission = await _notificationService.hasPermissions();
      debugPrint('🔐 Current permission status: $hasPermission');
      
      if (!hasPermission) {
        debugPrint('🔐 Requesting notification permissions...');
        final granted = await _notificationService.requestPermissions();
        debugPrint('🔐 Permission request result: $granted');
        if (!granted) {
          debugPrint('❌ Notification permission not granted, cannot start reminder service');
          return;
        }
      } else {
        debugPrint('✅ Notification permissions already granted');
      }

      // 取消所有之前的通知
      debugPrint('🧹 Cancelling all previous notifications...');
      await _notificationService.cancelAllNotifications();
      debugPrint('✅ All previous notifications cancelled');
      
      // 预调度多个本地通知，确保在后台和关屏状态下也能正常工作
      debugPrint('📅 Starting to schedule multiple notifications...');
      await _scheduleMultipleNotifications();
      debugPrint('✅ Multiple notifications scheduled successfully');

      _isRunning = true;
      debugPrint('🎉 Simple reminder service started using local notification scheduling, interval: $_reminderIntervalSeconds seconds');
      debugPrint('📊 Service status: isRunning=$_isRunning, maxNotifications=$_maxScheduledNotifications');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to start simple reminder service: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _isRunning = false;
      throw Exception('Failed to start reminder service: $e');
    }
  }

  /**
   * 停止定时提醒
   * @author 助手
   * @date 2025-01-02
   * @return Future<void>
   */
  Future<void> stopReminder() async {
    // 取消所有预调度的通知
    await _notificationService.cancelAllNotifications();
    
    _isRunning = false;
    _notificationCounter = 1;
    debugPrint('🛑 Simple reminder service stopped and all scheduled notifications cancelled');
  }

  /**
   * 预调度多个本地通知
   * @author 助手
   * @date 2025-01-02
   * @return Future<void>
   */
  Future<void> _scheduleMultipleNotifications() async {
    try {
      final DateTime now = DateTime.now();
      debugPrint('⏰ Current time: ${now.toString()}');
      debugPrint('📊 Will schedule $_maxScheduledNotifications notifications with $_reminderIntervalSeconds seconds interval');
      
      // 预调度多个通知，每隔指定秒数一个
      for (int i = 0; i < _maxScheduledNotifications; i++) {
        final DateTime scheduledTime = now.add(Duration(seconds: _reminderIntervalSeconds * (i + 1)));
        final int notificationId = _notificationCounter + i;
        
        debugPrint('📅 Scheduling notification #${i + 1}: ID=$notificationId, time=${scheduledTime.toString()}');
        
        await _notificationService.scheduleExerciseReminder(
          notificationId: notificationId,
          scheduledDate: scheduledTime,
          activityName: 'Walking in place',
          customMessage: 'Time to walk in place! (#${i + 1})',
        );
        
        debugPrint('✅ Successfully scheduled reminder #${i + 1} for ${scheduledTime.toString()}');
        
        // 每10个通知输出一次进度
        if ((i + 1) % 10 == 0) {
          debugPrint('📊 Progress: ${i + 1}/$_maxScheduledNotifications notifications scheduled');
        }
      }
      
      debugPrint('🎉 Successfully scheduled all $_maxScheduledNotifications notifications');
      
      // 验证已调度的通知
      final pendingNotifications = await _notificationService.getPendingNotifications();
      debugPrint('📋 Pending notifications count: ${pendingNotifications.length}');
      
      // 显示前5个即将到来的通知
      for (int i = 0; i < pendingNotifications.length && i < 5; i++) {
        final notification = pendingNotifications[i];
        debugPrint('📋 Pending notification ${i + 1}: ID=${notification.id}, title="${notification.title}", body="${notification.body}"');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to schedule notifications: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /**
   * 检查提醒服务是否正在运行
   * @author 助手
   * @date 2025-01-02
   * @return bool 是否正在运行
   */
  bool get isRunning => _isRunning;

  /**
   * 获取已发送的提醒次数
   * @author 助手
   * @date 2025-01-02
   * @return int 提醒次数
   */
  int get reminderCount => _notificationCounter - 1;
}