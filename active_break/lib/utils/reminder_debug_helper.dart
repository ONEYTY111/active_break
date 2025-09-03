/**
 * 提醒功能调试助手
 * @Description: 用于调试5分钟间隔提醒功能的工具类
 * @author Author
 * @date Current date and time
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2025
 * @version V1.0
 */
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/reminder_scheduler_service.dart';
import '../services/database_service.dart';
import '../models/reminder_and_tips.dart';

/**
 * 提醒功能调试助手类
 * @Description: 提供各种调试和测试提醒功能的方法
 * @author Author
 * @date Current date and time
 */
class ReminderDebugHelper {
  static final DatabaseService _databaseService = DatabaseService();
  static final NotificationService _notificationService = NotificationService();
  static final ReminderSchedulerService _reminderService = ReminderSchedulerService();

  /**
   * 运行完整的5分钟提醒诊断
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> runFullDiagnostic(int userId) async {
    debugPrint('=== 开始5分钟提醒功能完整诊断 ===');
    
    final List<String> issues = [];
    final List<String> solutions = [];
    
    try {
      // 1. 检查通知权限
      final permissionResult = await _checkNotificationPermissionsWithResult();
      if (!permissionResult['hasPermission']) {
        issues.add('通知权限未授予');
        solutions.add('请在系统设置中开启应用的通知权限');
      }
      
      // 2. 检查提醒设置
      final settingsResult = await _checkReminderSettingsWithResult(userId);
      if (settingsResult['count'] == 0) {
        issues.add('未找到任何提醒设置');
        solutions.add('请先在应用中创建5分钟间隔的提醒设置');
      } else if (!settingsResult['has5MinuteEnabled']) {
        issues.add('没有启用的5分钟间隔提醒');
        solutions.add('请确保5分钟间隔的提醒设置已启用');
      }
      
      // 3. 检查WorkManager任务
      await _checkWorkManagerTasks(userId);
      
      // 4. 测试提醒逻辑
      await _testReminderLogic(userId);
      
      // 5. 检查提醒历史
      final historyResult = await _checkReminderHistoryWithResult(userId);
      if (historyResult['recentCount'] == 0) {
        issues.add('最近15分钟内没有提醒触发记录');
        solutions.add('这可能表示提醒逻辑存在问题，请检查时间设置和间隔配置');
      }
      
      // 6. 发送测试通知
      await _sendTestNotification();
      
      // 7. 生成诊断报告
      await _generateDiagnosticReport(issues, solutions);
      
      debugPrint('=== 5分钟提醒功能诊断完成 ===');
      
    } catch (e, stackTrace) {
      debugPrint('诊断过程中发生错误: $e');
      debugPrint('错误堆栈: $stackTrace');
      issues.add('诊断过程中发生严重错误');
      solutions.add('请重启应用后重试，如果问题持续存在，请联系技术支持');
      await _generateDiagnosticReport(issues, solutions);
    }
  }

  /**
   * 检查通知权限
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  static Future<void> _checkNotificationPermissions() async {
    debugPrint('\n--- 检查通知权限 ---');
    
    try {
      await _notificationService.initialize();
      final hasPermission = await _notificationService.hasPermissions();
      
      debugPrint('通知权限状态: ${hasPermission ? "已授予" : "未授予"}');
      
      if (!hasPermission) {
        debugPrint('⚠️ 通知权限未授予，这可能是收不到提醒的原因');
        debugPrint('建议: 请在系统设置中开启应用的通知权限');
      } else {
        debugPrint('✓ 通知权限正常');
      }
    } catch (e) {
      debugPrint('✗ 检查通知权限时发生错误: $e');
    }
  }

  /**
   * 检查提醒设置
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> _checkReminderSettings(int userId) async {
    debugPrint('\n--- 检查提醒设置 ---');
    
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'reminder_settings',
        where: 'user_id = ? AND deleted = ?',
        whereArgs: [userId, 0],
      );
      
      debugPrint('找到 ${maps.length} 个提醒设置');
      
      for (int i = 0; i < maps.length; i++) {
        final setting = ReminderSetting.fromMap(maps[i]);
        debugPrint('\n提醒设置 ${i + 1}:');
        debugPrint('  - ID: ${setting.reminderId}');
        debugPrint('  - 活动类型ID: ${setting.activityTypeId}');
        debugPrint('  - 启用状态: ${setting.enabled ? "启用" : "禁用"}');
        debugPrint('  - 间隔: ${setting.intervalValue} 分钟');
        debugPrint('  - 开始时间: ${setting.startTime.hour}:${setting.startTime.minute.toString().padLeft(2, '0')}');
        debugPrint('  - 结束时间: ${setting.endTime.hour}:${setting.endTime.minute.toString().padLeft(2, '0')}');
        debugPrint('  - 创建时间: ${setting.createdAt?.toIso8601String() ?? "未知"}');
        
        if (setting.enabled && setting.intervalValue == 5) {
          debugPrint('  ✓ 发现5分钟间隔的启用提醒');
        }
      }
      
      if (maps.isEmpty) {
        debugPrint('⚠️ 未找到任何提醒设置');
        debugPrint('建议: 请先在应用中设置5分钟间隔的提醒');
      }
    } catch (e) {
      debugPrint('✗ 检查提醒设置时发生错误: $e');
    }
  }

  /**
   * 检查WorkManager任务
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> _checkWorkManagerTasks(int userId) async {
    debugPrint('\n--- 检查WorkManager任务 ---');
    
    try {
      await _reminderService.initialize();
      debugPrint('✓ ReminderSchedulerService 初始化成功');
      
      // 重新调度任务
      await _reminderService.scheduleReminders(userId);
      debugPrint('✓ 提醒任务已重新调度');
      
      debugPrint('注意: WorkManager任务在后台运行，无法直接查看状态');
      debugPrint('任务将每15分钟检查一次是否需要发送5分钟间隔提醒');
      
    } catch (e) {
      debugPrint('✗ 检查WorkManager任务时发生错误: $e');
    }
  }

  /**
   * 测试提醒逻辑
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> _testReminderLogic(int userId) async {
    debugPrint('\n--- 测试提醒逻辑 ---');
    
    try {
      debugPrint('执行立即提醒检查...');
      await _reminderService.checkAndTriggerReminders(userId);
      debugPrint('✓ 提醒逻辑测试完成');
      
      // 等待一秒钟让日志记录完成
      await Future.delayed(const Duration(seconds: 1));
      
    } catch (e) {
      debugPrint('✗ 测试提醒逻辑时发生错误: $e');
    }
  }

  /**
   * 检查提醒历史
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> _checkReminderHistory(int userId) async {
    debugPrint('\n--- 检查提醒历史 ---');
    
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
        debugPrint('  无提醒记录');
        debugPrint('  这可能表示提醒从未被触发过');
      } else {
        for (int i = 0; i < logs.length; i++) {
          final log = logs[i];
          final triggeredAt = DateTime.fromMillisecondsSinceEpoch(log['triggered_at']);
          final now = DateTime.now();
          final diff = now.difference(triggeredAt);
          
          debugPrint('  ${i + 1}. 活动类型ID: ${log['activity_type_id']}, 时间: ${triggeredAt.toIso8601String()}, ${diff.inMinutes}分钟前');
        }
      }
    } catch (e) {
      debugPrint('✗ 检查提醒历史时发生错误: $e');
    }
  }

  /**
   * 发送测试通知并显示详细结果
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  static Future<void> _sendTestNotification() async {
    debugPrint('\n--- 发送测试通知 ---');
    
    try {
      await _notificationService.initialize();
      final Map<String, dynamic> result = await _notificationService.showTestReminder();
      
      debugPrint('测试通知结果:');
      debugPrint('  成功状态: ${result['success']}');
      debugPrint('  结果消息: ${result['message']}');
      debugPrint('  测试时间: ${result['timestamp']}');
      
      debugPrint('\n详细执行步骤:');
      final List<String> details = result['details'] ?? [];
      for (int i = 0; i < details.length; i++) {
        debugPrint('  ${i + 1}. ${details[i]}');
      }
      
      if (result['success'] == true) {
        debugPrint('\n✅ 测试通知发送成功！');
        debugPrint('请检查您的通知栏是否收到测试通知。');
        debugPrint('如果没有看到通知，可能的原因:');
        debugPrint('  1. 通知可能被系统延迟显示');
        debugPrint('  2. 勿扰模式可能已开启');
        debugPrint('  3. 应用通知设置可能被禁用');
        debugPrint('  4. 系统电池优化可能影响通知显示');
      } else {
        debugPrint('\n❌ 测试通知发送失败');
        debugPrint('失败原因: ${result['message']}');
        debugPrint('\n建议解决方案:');
        debugPrint('  1. 检查应用通知权限设置');
        debugPrint('  2. 在系统设置中允许应用发送通知');
        debugPrint('  3. 关闭勿扰模式');
        debugPrint('  4. 重启应用后重试');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ 发送测试通知时发生严重错误: $e');
      debugPrint('错误堆栈: $stackTrace');
      debugPrint('\n紧急解决方案:');
      debugPrint('  1. 完全关闭应用后重新打开');
      debugPrint('  2. 检查设备存储空间是否充足');
      debugPrint('  3. 重启设备');
      debugPrint('  4. 重新安装应用');
    }
  }

  /**
   * 创建5分钟测试提醒
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> create5MinuteTestReminder(int userId) async {
    debugPrint('\n--- 创建5分钟测试提醒 ---');
    
    try {
      final now = DateTime.now();
      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
      );
      final endTime = startTime.add(const Duration(hours: 1)); // 1小时测试窗口
      
      final reminderSetting = ReminderSetting(
        userId: userId,
        activityTypeId: 1, // 肩颈拉伸
        enabled: true,
        intervalValue: 5, // 5分钟间隔
        intervalWeek: 1,
        startTime: startTime,
        endTime: endTime,
        createdAt: now,
        updatedAt: now,
      );
      
      await _databaseService.insertOrUpdateReminderSetting(reminderSetting);
      debugPrint('✓ 5分钟测试提醒已创建');
      debugPrint('开始时间: ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}');
      debugPrint('结束时间: ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}');
      debugPrint('间隔: 5分钟');
      
      // 重新调度任务
      await _reminderService.scheduleReminders(userId);
      debugPrint('✓ 提醒任务已重新调度');
      
    } catch (e) {
      debugPrint('✗ 创建5分钟测试提醒时发生错误: $e');
    }
  }

  /**
   * 清理测试数据
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   */
  static Future<void> cleanupTestData(int userId) async {
    debugPrint('\n--- 清理测试数据 ---');
    
    try {
      final db = await _databaseService.database;
      
      // 删除提醒日志
      await db.delete(
        'reminder_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      debugPrint('✓ 测试数据已清理');
    } catch (e) {
      debugPrint('✗ 清理测试数据时发生错误: $e');
    }
  }

  /**
   * 检查通知权限并返回结果
   * @author Author
   * @date Current date and time
   * @return Future<Map<String, dynamic>> 权限检查结果
   */
  static Future<Map<String, dynamic>> _checkNotificationPermissionsWithResult() async {
    debugPrint('\n--- 检查通知权限 ---');
    
    final Map<String, dynamic> result = {
      'hasPermission': false,
      'details': <String>[],
    };
    
    try {
      await _notificationService.initialize();
      final hasPermission = await _notificationService.hasPermissions();
      
      result['hasPermission'] = hasPermission;
      result['details'].add('通知权限状态: ${hasPermission ? "已授予" : "未授予"}');
      
      debugPrint('通知权限状态: ${hasPermission ? "已授予" : "未授予"}');
      
      if (!hasPermission) {
        debugPrint('⚠️ 通知权限未授予，这可能是收不到提醒的原因');
        debugPrint('建议: 请在系统设置中开启应用的通知权限');
        result['details'].add('⚠️ 通知权限未授予，这可能是收不到提醒的原因');
        result['details'].add('建议: 请在系统设置中开启应用的通知权限');
      } else {
        debugPrint('✓ 通知权限正常');
        result['details'].add('✓ 通知权限正常');
      }
    } catch (e) {
      debugPrint('✗ 检查通知权限时发生错误: $e');
      result['details'].add('✗ 检查通知权限时发生错误: $e');
    }
    
    return result;
  }

  /**
   * 检查提醒设置并返回结果
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<Map<String, dynamic>> 设置检查结果
   */
  static Future<Map<String, dynamic>> _checkReminderSettingsWithResult(int userId) async {
    debugPrint('\n--- 检查提醒设置 ---');
    
    final Map<String, dynamic> result = {
      'count': 0,
      'has5MinuteEnabled': false,
      'details': <String>[],
    };
    
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'reminder_settings',
        where: 'user_id = ? AND deleted = ?',
        whereArgs: [userId, 0],
      );
      
      result['count'] = maps.length;
      debugPrint('找到 ${maps.length} 个提醒设置');
      result['details'].add('找到 ${maps.length} 个提醒设置');
      
      bool has5MinuteEnabled = false;
      
      for (int i = 0; i < maps.length; i++) {
        final setting = ReminderSetting.fromMap(maps[i]);
        debugPrint('\n提醒设置 ${i + 1}:');
        debugPrint('  - ID: ${setting.reminderId}');
        debugPrint('  - 活动类型ID: ${setting.activityTypeId}');
        debugPrint('  - 启用状态: ${setting.enabled ? "启用" : "禁用"}');
        debugPrint('  - 间隔: ${setting.intervalValue} 分钟');
        debugPrint('  - 开始时间: ${setting.startTime.hour}:${setting.startTime.minute.toString().padLeft(2, '0')}');
        debugPrint('  - 结束时间: ${setting.endTime.hour}:${setting.endTime.minute.toString().padLeft(2, '0')}');
        
        result['details'].add('提醒设置 ${i + 1}: 活动类型${setting.activityTypeId}, ${setting.enabled ? "启用" : "禁用"}, ${setting.intervalValue}分钟间隔');
        
        if (setting.enabled && setting.intervalValue == 5) {
          has5MinuteEnabled = true;
          debugPrint('  ✓ 发现5分钟间隔的启用提醒');
          result['details'].add('  ✓ 发现5分钟间隔的启用提醒');
        }
      }
      
      result['has5MinuteEnabled'] = has5MinuteEnabled;
      
      if (maps.isEmpty) {
        debugPrint('⚠️ 未找到任何提醒设置');
        debugPrint('建议: 请先在应用中设置5分钟间隔的提醒');
        result['details'].add('⚠️ 未找到任何提醒设置');
        result['details'].add('建议: 请先在应用中设置5分钟间隔的提醒');
      } else if (!has5MinuteEnabled) {
        debugPrint('⚠️ 没有启用的5分钟间隔提醒');
        debugPrint('建议: 请确保5分钟间隔的提醒设置已启用');
        result['details'].add('⚠️ 没有启用的5分钟间隔提醒');
        result['details'].add('建议: 请确保5分钟间隔的提醒设置已启用');
      }
    } catch (e) {
      debugPrint('✗ 检查提醒设置时发生错误: $e');
      result['details'].add('✗ 检查提醒设置时发生错误: $e');
    }
    
    return result;
  }

  /**
   * 检查提醒历史并返回结果
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<Map<String, dynamic>> 历史检查结果
   */
  static Future<Map<String, dynamic>> _checkReminderHistoryWithResult(int userId) async {
    debugPrint('\n--- 检查提醒历史 ---');
    
    final Map<String, dynamic> result = {
      'totalCount': 0,
      'recentCount': 0,
      'details': <String>[],
    };
    
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> logs = await db.query(
        'reminder_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'triggered_at DESC',
        limit: 10,
      );
      
      result['totalCount'] = logs.length;
      debugPrint('最近 ${logs.length} 条提醒记录:');
      result['details'].add('最近 ${logs.length} 条提醒记录');
      
      if (logs.isEmpty) {
        debugPrint('  无提醒记录');
        debugPrint('  这可能表示提醒从未被触发过');
        result['details'].add('  无提醒记录 - 这可能表示提醒从未被触发过');
      } else {
        int recentCount = 0;
        final now = DateTime.now();
        
        for (int i = 0; i < logs.length; i++) {
          final log = logs[i];
          final triggeredAt = DateTime.fromMillisecondsSinceEpoch(log['triggered_at']);
          final diff = now.difference(triggeredAt);
          
          if (diff.inMinutes <= 15) {
            recentCount++;
          }
          
          debugPrint('  ${i + 1}. 活动类型ID: ${log['activity_type_id']}, 时间: ${triggeredAt.toIso8601String()}, ${diff.inMinutes}分钟前');
          result['details'].add('  ${i + 1}. 活动类型ID: ${log['activity_type_id']}, ${diff.inMinutes}分钟前');
        }
        
        result['recentCount'] = recentCount;
        
        if (recentCount > 0) {
          debugPrint('✓ 最近15分钟内有 $recentCount 条触发记录');
          result['details'].add('✓ 最近15分钟内有 $recentCount 条触发记录');
        } else {
          debugPrint('⚠️ 最近15分钟内没有触发记录');
          result['details'].add('⚠️ 最近15分钟内没有触发记录');
        }
      }
    } catch (e) {
      debugPrint('✗ 检查提醒历史时发生错误: $e');
      result['details'].add('✗ 检查提醒历史时发生错误: $e');
    }
    
    return result;
  }

  /**
   * 生成诊断报告
   * @author Author
   * @date Current date and time
   * @param issues 发现的问题列表
   * @param solutions 解决方案列表
   * @return Future<void>
   */
  static Future<void> _generateDiagnosticReport(List<String> issues, List<String> solutions) async {
    debugPrint('\n=== 诊断报告 ===');
    
    if (issues.isEmpty) {
      debugPrint('🎉 恭喜！未发现明显问题');
      debugPrint('如果仍然收不到提醒，可能的原因:');
      debugPrint('  1. 系统电池优化设置限制了后台运行');
      debugPrint('  2. 勿扰模式或专注模式已开启');
      debugPrint('  3. 系统通知设置中禁用了特定类型的通知');
      debugPrint('  4. 设备存储空间不足影响应用运行');
      debugPrint('\n建议操作:');
      debugPrint('  1. 在系统设置中将本应用添加到电池优化白名单');
      debugPrint('  2. 检查勿扰模式设置，确保允许应用通知');
      debugPrint('  3. 重启设备后重试');
      debugPrint('  4. 确保设备有足够的存储空间');
    } else {
      debugPrint('❌ 发现 ${issues.length} 个问题:');
      for (int i = 0; i < issues.length; i++) {
        debugPrint('  ${i + 1}. ${issues[i]}');
      }
      
      debugPrint('\n💡 建议解决方案:');
      for (int i = 0; i < solutions.length; i++) {
        debugPrint('  ${i + 1}. ${solutions[i]}');
      }
      
      debugPrint('\n🔧 通用解决步骤:');
      debugPrint('  1. 确保应用有通知权限');
      debugPrint('  2. 在系统设置中关闭应用的电池优化');
      debugPrint('  3. 检查系统勿扰模式设置');
      debugPrint('  4. 重启应用或设备');
      debugPrint('  5. 如果问题持续，请尝试重新安装应用');
    }
    
    debugPrint('\n📱 设备特定建议:');
    debugPrint('Android设备:');
    debugPrint('  - 在"设置 > 应用 > 特殊访问权限 > 电池优化"中将本应用设为"不优化"');
    debugPrint('  - 在"设置 > 应用 > 本应用 > 通知"中确保所有通知类型都已开启');
    debugPrint('  - 检查"设置 > 勿扰模式"，确保允许应用通知');
    debugPrint('\niOS设备:');
    debugPrint('  - 在"设置 > 通知 > 本应用"中开启允许通知');
    debugPrint('  - 在"设置 > 屏幕时间 > 应用限额"中确保本应用没有被限制');
    debugPrint('  - 在"设置 > 勿扰模式"中配置允许通知的应用');
    
    debugPrint('=== 诊断报告结束 ===\n');
  }
}