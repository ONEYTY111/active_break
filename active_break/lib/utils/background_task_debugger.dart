/**
 * 后台任务调试工具
 * @Description: 专门用于调试iOS后台任务功能的工具类
 * @className: BackgroundTaskDebugger
 * @author Author
 * @date Current date and time
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2024
 * @version V1.0
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// 后台任务调试器类
/// 提供iOS后台任务的调试和监控功能
class BackgroundTaskDebugger {
  /// 方法通道，用于与iOS原生代码通信
  static const MethodChannel _channel = MethodChannel(
    'com.activebreak/background_reminder',
  );

  /// 检查后台任务状态
  /// @return Map<String, dynamic> 包含后台任务状态信息的映射
  /// @throws PlatformException 当平台调用失败时抛出异常
  static Future<Map<String, dynamic>> checkBackgroundTaskStatus() async {
    try {
      if (!Platform.isIOS) {
        return {'error': '此功能仅在iOS平台可用', 'platform': Platform.operatingSystem};
      }

      debugPrint('🔍 开始检查iOS后台任务状态...');

      final result = await _channel.invokeMethod('checkBackgroundTaskStatus');

      if (result is Map) {
        final status = Map<String, dynamic>.from(result);
        debugPrint('📊 后台任务状态检查结果:');
        debugPrint('  - 后台任务已注册: ${status['backgroundTaskRegistered']}');
        debugPrint('  - 任务标识符: ${status['taskIdentifier']}');
        debugPrint('  - 后台模式已启用: ${status['backgroundModesEnabled']}');
        debugPrint('  - 通知权限已授予: ${status['notificationPermissionGranted']}');

        return status;
      } else {
        throw PlatformException(
          code: 'INVALID_RESPONSE',
          message: '收到无效的响应格式',
          details: result,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('❌ 检查后台任务状态失败: ${e.message}');
      return {
        'error': e.message ?? '未知错误',
        'code': e.code,
        'details': e.details,
      };
    } catch (e) {
      debugPrint('❌ 检查后台任务状态时发生未知错误: $e');
      return {'error': '未知错误: $e'};
    }
  }

  /// 手动触发后台任务（用于测试）
  /// @return Map<String, dynamic> 包含触发结果的映射
  /// @throws PlatformException 当平台调用失败时抛出异常
  static Future<Map<String, dynamic>> triggerBackgroundTask() async {
    try {
      if (!Platform.isIOS) {
        return {'error': '此功能仅在iOS平台可用', 'platform': Platform.operatingSystem};
      }

      debugPrint('🧪 手动触发后台任务测试...');

      final result = await _channel.invokeMethod('triggerBackgroundTask');

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        debugPrint('✅ 后台任务触发结果: ${response['message']}');
        return response;
      } else {
        throw PlatformException(
          code: 'INVALID_RESPONSE',
          message: '收到无效的响应格式',
          details: result,
        );
      }
    } on PlatformException catch (e) {
      debugPrint('❌ 触发后台任务失败: ${e.message}');
      return {
        'error': e.message ?? '未知错误',
        'code': e.code,
        'details': e.details,
      };
    } catch (e) {
      debugPrint('❌ 触发后台任务时发生未知错误: $e');
      return {'error': '未知错误: $e'};
    }
  }

  /// 执行完整的后台任务诊断
  /// @return Map<String, dynamic> 包含完整诊断结果的映射
  static Future<Map<String, dynamic>> performFullDiagnostic() async {
    debugPrint('🔬 开始执行完整的后台任务诊断...');

    final diagnostic = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'platformVersion': Platform.operatingSystemVersion,
    };

    // 检查后台任务状态
    final taskStatus = await checkBackgroundTaskStatus();
    diagnostic['backgroundTaskStatus'] = taskStatus;

    // 分析诊断结果
    final issues = <String>[];
    final recommendations = <String>[];

    if (taskStatus.containsKey('error')) {
      issues.add('后台任务状态检查失败: ${taskStatus['error']}');
      recommendations.add('检查iOS版本是否支持BGTaskScheduler（需要iOS 13+）');
    } else {
      if (taskStatus['backgroundTaskRegistered'] != true) {
        issues.add('后台任务未正确注册');
        recommendations.add('检查AppDelegate.swift中的BGTaskScheduler注册代码');
      }

      if (taskStatus['backgroundModesEnabled'] != true) {
        issues.add('Info.plist中未启用后台模式');
        recommendations.add('在Info.plist中添加UIBackgroundModes配置');
      }

      if (taskStatus['notificationPermissionGranted'] != true) {
        issues.add('通知权限未授予');
        recommendations.add('请在设置中授予应用通知权限');
      }
    }

    diagnostic['issues'] = issues;
    diagnostic['recommendations'] = recommendations;
    diagnostic['overallStatus'] = issues.isEmpty ? 'healthy' : 'issues_found';

    // 输出诊断报告
    debugPrint('📋 后台任务诊断报告:');
    debugPrint('  状态: ${diagnostic['overallStatus']}');
    if (issues.isNotEmpty) {
      debugPrint('  发现的问题:');
      for (final issue in issues) {
        debugPrint('    - $issue');
      }
      debugPrint('  建议:');
      for (final recommendation in recommendations) {
        debugPrint('    - $recommendation');
      }
    } else {
      debugPrint('  ✅ 所有检查项目都正常');
    }

    return diagnostic;
  }

  /// 生成诊断报告的可读字符串
  /// @param diagnostic 诊断结果映射
  /// @return String 格式化的诊断报告字符串
  static String formatDiagnosticReport(Map<String, dynamic> diagnostic) {
    final buffer = StringBuffer();

    buffer.writeln('=== iOS后台任务诊断报告 ===');
    buffer.writeln('时间: ${diagnostic['timestamp']}');
    buffer.writeln(
      '平台: ${diagnostic['platform']} ${diagnostic['platformVersion']}',
    );
    buffer.writeln('状态: ${diagnostic['overallStatus']}');
    buffer.writeln();

    if (diagnostic['issues'] != null &&
        (diagnostic['issues'] as List).isNotEmpty) {
      buffer.writeln('发现的问题:');
      for (final issue in diagnostic['issues'] as List) {
        buffer.writeln('  - $issue');
      }
      buffer.writeln();

      buffer.writeln('建议:');
      for (final recommendation in diagnostic['recommendations'] as List) {
        buffer.writeln('  - $recommendation');
      }
    } else {
      buffer.writeln('✅ 所有检查项目都正常');
    }

    return buffer.toString();
  }
}
