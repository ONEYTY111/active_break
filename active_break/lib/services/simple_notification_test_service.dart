/**
 * 简单通知测试服务
 * @Description: 用于排查iOS通知问题的简化测试服务，绕过复杂逻辑直接发送通知
 * @author Author
 * @date Current date and time
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2025
 * @version V1.0
 */
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../services/notification_service.dart';

/**
 * 简单通知测试服务类
 * @Description: 提供最简单的定时通知功能，用于排查通知权限和逻辑问题
 * @author Author
 * @date Current date and time
 */
class SimpleNotificationTestService {
  static SimpleNotificationTestService? _instance;
  Timer? _timer;
  NotificationService? _notificationService;
  bool _isRunning = false;
  int _notificationCounter = 0;

  /**
   * 获取单例实例
   * @author Author
   * @date Current date and time
   * @return SimpleNotificationTestService 服务实例
   */
  static SimpleNotificationTestService get instance {
    _instance ??= SimpleNotificationTestService._();
    return _instance!;
  }

  /**
   * 私有构造函数
   * @author Author
   * @date Current date and time
   */
  SimpleNotificationTestService._();

  /**
   * 启动简单的每分钟通知测试
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当通知服务初始化失败时抛出异常
   */
  Future<void> startSimpleTest(int userId) async {
    if (_isRunning) {
      debugPrint('简单通知测试已在运行中');
      return;
    }

    try {
      debugPrint('=== 启动简单通知测试 ===');
      debugPrint('用户ID: $userId');
      debugPrint('平台: ${Platform.operatingSystem}');
      debugPrint('调试模式: $kDebugMode');
      
      // 停止所有现有的 WorkManager 任务，避免干扰
      try {
        await Workmanager().cancelAll();
        debugPrint('已停止所有 WorkManager 任务');
      } catch (e) {
        debugPrint('停止 WorkManager 任务时出错: $e');
      }
      
      // 初始化通知服务
      _notificationService = NotificationService();
      await _notificationService!.initialize();
      debugPrint('通知服务初始化成功');

      // 检查通知权限
      final hasPermission = await _notificationService!.hasPermissions();
      debugPrint('通知权限状态: ${hasPermission ? "已授予" : "未授予"}');
      
      if (!hasPermission) {
        debugPrint('请求通知权限...');
        await _notificationService!.requestPermissions();
        final newPermission = await _notificationService!.hasPermissions();
        debugPrint('权限请求后状态: ${newPermission ? "已授予" : "未授予"}');
      }

      // 立即发送第一条测试通知
      await _sendTestNotification(userId);
      
      // 启动定时器，每分钟发送一次
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        await _sendTestNotification(userId);
      });
      
      _isRunning = true;
      debugPrint('简单通知测试已启动，每分钟发送一次测试消息');
      
    } catch (e, stackTrace) {
      debugPrint('启动简单通知测试失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  /**
   * 发送测试通知
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当通知发送失败时抛出异常
   */
  Future<void> _sendTestNotification(int userId) async {
    try {
      _notificationCounter++;
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      debugPrint('=== 发送测试通知 #$_notificationCounter ===');
      debugPrint('时间: $timeStr');
      
      // 生成唯一的通知ID
      final notificationId = 10000 + _notificationCounter;
      
      // 发送固定内容的测试通知
      await _notificationService!.showExerciseReminder(
        notificationId: notificationId,
        activityName: '测试消息',
        customMessage: '这是第$_notificationCounter条测试消息 - $timeStr',
      );
      
      debugPrint('✅ 测试通知 #$_notificationCounter 发送成功');
      debugPrint('通知ID: $notificationId');
      debugPrint('通知内容: 测试消息 - 这是第$_notificationCounter条测试消息 - $timeStr');
      
    } catch (e, stackTrace) {
      debugPrint('❌ 发送测试通知失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
    }
  }

  /**
   * 停止简单通知测试
   * @author Author
   * @date Current date and time
   * @return void
   */
  void stopSimpleTest() {
    if (!_isRunning) {
      debugPrint('简单通知测试未在运行');
      return;
    }

    debugPrint('=== 停止简单通知测试 ===');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _notificationCounter = 0;
    debugPrint('简单通知测试已停止');
  }

  /**
   * 获取测试状态
   * @author Author
   * @date Current date and time
   * @return bool 是否正在运行
   */
  bool get isRunning => _isRunning;

  /**
   * 获取已发送的通知数量
   * @author Author
   * @date Current date and time
   * @return int 通知计数
   */
  int get notificationCount => _notificationCounter;

  /**
   * 立即发送一条测试通知（用于手动测试）
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void>
   * @throws Exception 当通知发送失败时抛出异常
   */
  Future<void> sendImmediateTest(int userId) async {
    if (_notificationService == null) {
      _notificationService = NotificationService();
      await _notificationService!.initialize();
    }
    
    await _sendTestNotification(userId);
  }
}