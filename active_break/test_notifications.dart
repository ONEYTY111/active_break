import 'package:flutter/material.dart';
import 'lib/services/notification_service.dart';
import 'lib/services/reminder_scheduler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== 开始测试通知服务 ===');
  
  try {
    // 测试通知服务初始化
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ 通知服务初始化成功');
    
    // 测试权限请求
    final hasPermission = await notificationService.requestPermissions();
    print('✅ 通知权限状态: $hasPermission');
    
    // 测试显示通知
    await notificationService.showExerciseReminder(
      notificationId: 999,
      activityName: '测试运动提醒',
    );
    print('✅ 测试通知已发送');
    
    // 测试调度服务初始化
    final schedulerService = ReminderSchedulerService();
    await schedulerService.initialize();
    print('✅ 提醒调度服务初始化成功');
    
    print('=== 所有测试完成 ===');
    
  } catch (e, stackTrace) {
    print('❌ 测试失败: $e');
    print('堆栈跟踪: $stackTrace');
  }
}