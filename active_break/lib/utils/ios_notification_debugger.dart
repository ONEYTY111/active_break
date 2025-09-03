/**
 * iOS通知调试工具
 * @Description: 专门用于在iOS设备上调试通知功能的工具类
 * @className: IOSNotificationDebugger
 * @author Author
 * @date Current date and time
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2024
 * @version V1.0
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/notification_service.dart';
import '../services/intelligent_reminder_service.dart';
import '../services/database_service.dart';
import '../models/reminder_and_tips.dart';

/**
 * iOS通知调试器类
 * @Description: 提供iOS设备上通知功能的详细调试和测试
 * @author Author
 * @date Current date and time
 */
class IOSNotificationDebugger {
  static final NotificationService _notificationService = NotificationService();
  static final IntelligentReminderService _intelligentReminderService =
      IntelligentReminderService.instance;
  static final DatabaseService _databaseService = DatabaseService();

  /**
   * 执行完整的iOS通知调试
   * @author Author
   * @date Current date and time
   * @param context 上下文
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当调试过程中发生错误时抛出异常
   */
  static Future<void> performFullDebug(BuildContext context, int userId) async {
    debugPrint('\n🔍 === 开始iOS通知完整调试 ===');

    try {
      // 1. 检查平台
      await _checkPlatform();

      // 2. 检查通知权限
      await _checkNotificationPermissions();

      // 3. 测试立即通知
      await _testImmediateNotification();

      // 4. 检查数据库中的提醒设置
      await _checkReminderSettings(userId);

      // 5. 手动触发智能提醒检查
      await _manualTriggerIntelligentReminder(userId);

      // 6. 检查后台任务状态
      await _checkBackgroundTaskStatus(userId);

      // 7. 显示调试结果
      if (context.mounted) {
        _showDebugResults(context);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ iOS通知调试失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('调试失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    debugPrint('🔍 === iOS通知完整调试结束 ===\n');
  }

  /**
   * 检查当前平台
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  static Future<void> _checkPlatform() async {
    debugPrint('\n📱 === 检查平台信息 ===');
    debugPrint('当前平台: ${Platform.operatingSystem}');
    debugPrint('是否为iOS: ${Platform.isIOS}');
    debugPrint('是否为调试模式: $kDebugMode');

    if (!Platform.isIOS) {
      debugPrint('⚠️ 警告: 当前不是iOS平台，某些功能可能无法正常工作');
    }
  }

  /**
   * 检查通知权限
   * @author Author
   * @date Current date and time
   * @return Future<void>
   * @throws Exception 当权限检查失败时抛出异常
   */
  static Future<void> _checkNotificationPermissions() async {
    debugPrint('\n🔔 === 检查通知权限 ===');

    try {
      // 初始化通知服务
      await _notificationService.initialize();
      debugPrint('✅ 通知服务初始化成功');

      // 检查当前权限状态
      final bool hasPermission = await _notificationService.hasPermissions();
      debugPrint('当前通知权限状态: ${hasPermission ? "已授予" : "未授予"}');

      if (!hasPermission) {
        debugPrint('⚠️ 通知权限未授予，尝试请求权限...');
        final bool granted = await _notificationService.requestPermissions();
        debugPrint('权限请求结果: ${granted ? "已授予" : "被拒绝"}');

        if (!granted) {
          debugPrint('❌ 通知权限被拒绝！这是通知无法显示的主要原因！');
          debugPrint('💡 解决方案: 请到设置 > 通知 > Active Break 中手动开启通知权限');
        }
      } else {
        debugPrint('✅ 通知权限已正确授予');
      }
    } catch (e) {
      debugPrint('❌ 检查通知权限失败: $e');
      rethrow;
    }
  }

  /**
   * 测试立即通知
   * @author Author
   * @date Current date and time
   * @return Future<void>
   * @throws Exception 当通知发送失败时抛出异常
   */
  static Future<void> _testImmediateNotification() async {
    debugPrint('\n🚀 === 测试立即通知 ===');

    try {
      final result = await _notificationService.showTestReminder();

      debugPrint('测试通知结果:');
      debugPrint('  成功: ${result['success']}');
      debugPrint('  消息: ${result['message']}');
      debugPrint('  时间: ${result['timestamp']}');

      final List<String> details = result['details'] ?? [];
      for (final detail in details) {
        debugPrint('  详情: $detail');
      }

      if (result['success']) {
        debugPrint('✅ 立即通知测试成功！如果您没有看到通知，请检查设备的通知设置。');
      } else {
        debugPrint('❌ 立即通知测试失败！');
      }
    } catch (e) {
      debugPrint('❌ 测试立即通知失败: $e');
      rethrow;
    }
  }

  /**
   * 检查提醒设置
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当数据库查询失败时抛出异常
   */
  static Future<void> _checkReminderSettings(int userId) async {
    debugPrint('\n⚙️ === 检查提醒设置 ===');

    try {
      // 获取用户的所有提醒设置
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'reminder_settings',
        where: 'user_id = ? AND deleted = ?',
        whereArgs: [userId, 0],
      );

      final reminderSettings = List.generate(maps.length, (i) {
        return ReminderSetting.fromMap(maps[i]);
      });
      debugPrint('用户 $userId 的提醒设置数量: ${reminderSettings.length}');

      if (reminderSettings.isEmpty) {
        debugPrint('❌ 没有找到任何提醒设置！这可能是通知不工作的原因。');
        debugPrint('💡 解决方案: 请在应用中设置运动提醒。');
        return;
      }

      final now = DateTime.now();
      int activeCount = 0;

      for (int i = 0; i < reminderSettings.length; i++) {
        final reminder = reminderSettings[i];
        debugPrint('\n提醒设置 ${i + 1}:');
        debugPrint('  ID: ${reminder.reminderId}');
        debugPrint('  活动类型ID: ${reminder.activityTypeId}');
        debugPrint('  间隔值: ${reminder.intervalValue} 分钟');
        debugPrint('  启用状态: ${reminder.enabled}');
        debugPrint(
          '  开始时间: ${reminder.startTime.hour.toString().padLeft(2, '0')}:${reminder.startTime.minute.toString().padLeft(2, '0')}',
        );
        debugPrint(
          '  结束时间: ${reminder.endTime.hour.toString().padLeft(2, '0')}:${reminder.endTime.minute.toString().padLeft(2, '0')}',
        );

        if (reminder.enabled) {
          activeCount++;

          // 检查当前时间是否在提醒时间范围内
          final currentTime =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          final startTimeStr =
              '${reminder.startTime.hour.toString().padLeft(2, '0')}:${reminder.startTime.minute.toString().padLeft(2, '0')}';
          final endTimeStr =
              '${reminder.endTime.hour.toString().padLeft(2, '0')}:${reminder.endTime.minute.toString().padLeft(2, '0')}';
          final isInTimeRange = _isTimeInRange(
            currentTime,
            startTimeStr,
            endTimeStr,
          );
          debugPrint('  当前时间 $currentTime 是否在范围内: $isInTimeRange');

          if (isInTimeRange) {
            debugPrint('  ✅ 此提醒当前应该处于活跃状态');
          } else {
            debugPrint('  ⏰ 此提醒当前不在活跃时间范围内');
          }
        } else {
          debugPrint('  ❌ 此提醒已禁用');
        }
      }

      debugPrint('\n活跃的提醒设置数量: $activeCount');
    } catch (e) {
      debugPrint('❌ 检查提醒设置失败: $e');
      rethrow;
    }
  }

  /**
   * 手动触发智能提醒检查
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当智能提醒检查失败时抛出异常
   */
  static Future<void> _manualTriggerIntelligentReminder(int userId) async {
    debugPrint('\n🧠 === 手动触发智能提醒检查 ===');

    try {
      debugPrint('开始手动触发智能提醒检查...');
      final intelligentService = IntelligentReminderService.instance;
      await intelligentService.performReminderCheck(userId);
      debugPrint('✅ 智能提醒检查完成');

      // 等待一下，让通知有时间显示
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('❌ 手动触发智能提醒检查失败: $e');
      rethrow;
    }
  }

  /**
   * 检查后台任务状态
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> _checkBackgroundTaskStatus(int userId) async {
    debugPrint('\n🔄 === 检查后台任务状态 ===');

    try {
      final isRunning = _intelligentReminderService.isRunning;
      final currentUserId = _intelligentReminderService.currentUserId;

      debugPrint('智能提醒服务运行状态: $isRunning');
      debugPrint('当前用户ID: $currentUserId');

      if (!isRunning) {
        debugPrint('⚠️ 智能提醒服务未运行，尝试启动...');
        await _intelligentReminderService.startReminderSystem(userId);
        debugPrint('✅ 智能提醒服务已启动');
      } else if (currentUserId != userId) {
        debugPrint('⚠️ 智能提醒服务正在为其他用户运行，重新启动...');
        await _intelligentReminderService.stopReminderSystem();
        await _intelligentReminderService.startReminderSystem(userId);
        debugPrint('✅ 智能提醒服务已重新启动');
      } else {
        debugPrint('✅ 智能提醒服务正在为当前用户正常运行');
      }
    } catch (e) {
      debugPrint('❌ 检查后台任务状态失败: $e');
    }
  }

  /**
   * 显示调试结果
   * @author Author
   * @date Current date and time
   * @param context 上下文
   * @return void
   */
  static void _showDebugResults(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('iOS通知调试完成'),
          content: const SingleChildScrollView(
            child: Text(
              '调试过程已完成！\n\n'
              '请检查以下内容：\n'
              '1. 控制台日志中的详细信息\n'
              '2. 是否收到了测试通知\n'
              '3. 设备的通知设置是否正确\n\n'
              '如果仍然没有收到通知，请：\n'
              '• 检查设置 > 通知 > Active Break\n'
              '• 确保允许通知、横幅、声音等\n'
              '• 重启应用并重新测试',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  /**
   * 检查时间是否在指定范围内
   * @author Author
   * @date Current date and time
   * @param currentTime 当前时间 (HH:mm格式)
   * @param startTime 开始时间 (HH:mm格式)
   * @param endTime 结束时间 (HH:mm格式)
   * @return bool 是否在范围内
   */
  static bool _isTimeInRange(
    String currentTime,
    String startTime,
    String endTime,
  ) {
    try {
      final current = _parseTime(currentTime);
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);

      if (start <= end) {
        // 同一天内的时间范围
        return current >= start && current <= end;
      } else {
        // 跨天的时间范围
        return current >= start || current <= end;
      }
    } catch (e) {
      debugPrint('解析时间失败: $e');
      return false;
    }
  }

  /**
   * 解析时间字符串为分钟数
   * @author Author
   * @date Current date and time
   * @param timeStr 时间字符串 (HH:mm格式)
   * @return int 从00:00开始的分钟数
   * @throws FormatException 当时间格式不正确时抛出异常
   */
  static int _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $timeStr');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return hour * 60 + minute;
  }
}
