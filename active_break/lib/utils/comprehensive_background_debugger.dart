/**
 * 全面的iOS后台任务调试工具
 * @Description: 提供完整的iOS后台任务调试、监控和诊断功能
 * @className: ComprehensiveBackgroundDebugger
 * @author Author
 * @date Current date and time
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2024
 * @version V1.0
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 后台任务执行记录
class BackgroundTaskExecution {
  final DateTime timestamp;
  final String taskType;
  final bool success;
  final String? errorMessage;
  final Duration? executionTime;
  final Map<String, dynamic>? additionalData;

  BackgroundTaskExecution({
    required this.timestamp,
    required this.taskType,
    required this.success,
    this.errorMessage,
    this.executionTime,
    this.additionalData,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'taskType': taskType,
    'success': success,
    'errorMessage': errorMessage,
    'executionTime': executionTime?.inMilliseconds,
    'additionalData': additionalData,
  };

  factory BackgroundTaskExecution.fromJson(Map<String, dynamic> json) {
    return BackgroundTaskExecution(
      timestamp: DateTime.parse(json['timestamp']),
      taskType: json['taskType'],
      success: json['success'],
      errorMessage: json['errorMessage'],
      executionTime: json['executionTime'] != null 
          ? Duration(milliseconds: json['executionTime']) 
          : null,
      additionalData: json['additionalData'],
    );
  }
}

/// 系统限制检查结果
class SystemConstraintCheck {
  final bool lowPowerModeEnabled;
  final int batteryLevel;
  final bool isCharging;
  final String deviceModel;
  final String iosVersion;
  final bool backgroundAppRefreshEnabled;
  final DateTime checkTime;

  SystemConstraintCheck({
    required this.lowPowerModeEnabled,
    required this.batteryLevel,
    required this.isCharging,
    required this.deviceModel,
    required this.iosVersion,
    required this.backgroundAppRefreshEnabled,
    required this.checkTime,
  });

  Map<String, dynamic> toJson() => {
    'lowPowerModeEnabled': lowPowerModeEnabled,
    'batteryLevel': batteryLevel,
    'isCharging': isCharging,
    'deviceModel': deviceModel,
    'iosVersion': iosVersion,
    'backgroundAppRefreshEnabled': backgroundAppRefreshEnabled,
    'checkTime': checkTime.toIso8601String(),
  };
}

/// 全面的后台任务调试器
class ComprehensiveBackgroundDebugger {
  static const MethodChannel _channel = MethodChannel(
    'com.activebreak/background_reminder',
  );
  
  static const String _executionHistoryKey = 'background_task_execution_history';
  static const String _constraintHistoryKey = 'system_constraint_history';
  static const int _maxHistoryEntries = 100;
  
  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;
  
  /// 记录后台任务执行
  /// @param taskType 任务类型
  /// @param success 是否成功
  /// @param errorMessage 错误信息（如果有）
  /// @param executionTime 执行时间
  /// @param additionalData 额外数据
  /// @return Future<void>
  static Future<void> recordTaskExecution({
    required String taskType,
    required bool success,
    String? errorMessage,
    Duration? executionTime,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final execution = BackgroundTaskExecution(
        timestamp: DateTime.now(),
        taskType: taskType,
        success: success,
        errorMessage: errorMessage,
        executionTime: executionTime,
        additionalData: additionalData,
      );
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_executionHistoryKey) ?? [];
      
      // 添加新记录
      historyJson.add(jsonEncode(execution.toJson()));
      
      // 保持历史记录数量限制
      if (historyJson.length > _maxHistoryEntries) {
        historyJson.removeRange(0, historyJson.length - _maxHistoryEntries);
      }
      
      await prefs.setStringList(_executionHistoryKey, historyJson);
      
      debugPrint('📝 记录后台任务执行: $taskType, 成功: $success');
      if (errorMessage != null) {
        debugPrint('❌ 错误信息: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ 记录任务执行失败: $e');
    }
  }
  
  /// 获取任务执行历史
  /// @return Future<List<BackgroundTaskExecution>> 执行历史列表
  static Future<List<BackgroundTaskExecution>> getExecutionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_executionHistoryKey) ?? [];
      
      return historyJson.map((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        return BackgroundTaskExecution.fromJson(data);
      }).toList().reversed.toList(); // 最新的在前面
    } catch (e) {
      debugPrint('❌ 获取执行历史失败: $e');
      return [];
    }
  }
  
  /// 检查系统限制条件
  /// @return Future<SystemConstraintCheck> 系统限制检查结果
  static Future<SystemConstraintCheck> checkSystemConstraints() async {
    try {
      // 通过原生方法获取系统信息
      final systemInfo = await _channel.invokeMethod('getSystemInfo');
      
      final constraint = SystemConstraintCheck(
        lowPowerModeEnabled: systemInfo['lowPowerModeEnabled'] ?? false,
        batteryLevel: systemInfo['batteryLevel'] ?? 0,
        isCharging: systemInfo['isCharging'] ?? false,
        deviceModel: systemInfo['deviceModel'] ?? 'Unknown',
        iosVersion: systemInfo['iosVersion'] ?? 'Unknown',
        backgroundAppRefreshEnabled: systemInfo['backgroundAppRefreshEnabled'] ?? false,
        checkTime: DateTime.now(),
      );
      
      // 保存到历史记录
      await _saveConstraintHistory(constraint);
      
      return constraint;
    } catch (e) {
      debugPrint('❌ 检查系统限制失败: $e');
      // 返回默认值
      return SystemConstraintCheck(
        lowPowerModeEnabled: false,
        batteryLevel: 0,
        isCharging: false,
        deviceModel: 'Unknown',
        iosVersion: 'Unknown',
        backgroundAppRefreshEnabled: false,
        checkTime: DateTime.now(),
      );
    }
  }
  
  /// 保存系统限制检查历史
  /// @param constraint 系统限制检查结果
  /// @return Future<void>
  static Future<void> _saveConstraintHistory(SystemConstraintCheck constraint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_constraintHistoryKey) ?? [];
      
      historyJson.add(jsonEncode(constraint.toJson()));
      
      if (historyJson.length > _maxHistoryEntries) {
        historyJson.removeRange(0, historyJson.length - _maxHistoryEntries);
      }
      
      await prefs.setStringList(_constraintHistoryKey, historyJson);
    } catch (e) {
      debugPrint('❌ 保存系统限制历史失败: $e');
    }
  }
  
  /// 开始实时监控
  /// @param intervalSeconds 监控间隔（秒）
  /// @return Future<void>
  static Future<void> startRealTimeMonitoring({int intervalSeconds = 30}) async {
    if (_isMonitoring) {
      debugPrint('⚠️ 实时监控已在运行中');
      return;
    }
    
    _isMonitoring = true;
    debugPrint('🔍 开始实时监控后台任务状态，间隔: ${intervalSeconds}秒');
    
    _monitoringTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (timer) async {
        await _performMonitoringCheck();
      },
    );
    
    // 立即执行一次检查
    await _performMonitoringCheck();
  }
  
  /// 停止实时监控
  /// @return void
  static void stopRealTimeMonitoring() {
    if (!_isMonitoring) {
      debugPrint('⚠️ 实时监控未在运行');
      return;
    }
    
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    debugPrint('🛑 已停止实时监控');
  }
  
  /// 执行监控检查
  /// @return Future<void>
  static Future<void> _performMonitoringCheck() async {
    try {
      final timestamp = DateTime.now();
      debugPrint('\n🔍 === 实时监控检查 [${timestamp.toString()}] ===');
      
      // 检查系统限制
      final constraints = await checkSystemConstraints();
      debugPrint('🔋 电池电量: ${constraints.batteryLevel}%');
      debugPrint('⚡ 充电状态: ${constraints.isCharging ? "充电中" : "未充电"}');
      debugPrint('🔋 低电量模式: ${constraints.lowPowerModeEnabled ? "已启用" : "未启用"}');
      debugPrint('📱 后台应用刷新: ${constraints.backgroundAppRefreshEnabled ? "已启用" : "未启用"}');
      
      // 检查待执行的后台任务
      final pendingTasks = await _channel.invokeMethod('getPendingBackgroundTasks');
      debugPrint('📋 待执行后台任务数量: ${pendingTasks ?? 0}');
      
      // 分析是否存在限制因素
      final limitations = <String>[];
      if (constraints.lowPowerModeEnabled) {
        limitations.add('低电量模式已启用');
      }
      if (constraints.batteryLevel < 20 && !constraints.isCharging) {
        limitations.add('电池电量低且未充电');
      }
      if (!constraints.backgroundAppRefreshEnabled) {
        limitations.add('后台应用刷新被禁用');
      }
      
      if (limitations.isNotEmpty) {
        debugPrint('⚠️ 检测到可能影响后台任务的限制因素:');
        for (final limitation in limitations) {
          debugPrint('   - $limitation');
        }
      } else {
        debugPrint('✅ 系统状态良好，无明显限制因素');
      }
      
    } catch (e) {
      debugPrint('❌ 监控检查失败: $e');
    }
  }
  
  /// 生成完整的诊断报告
  /// @return Future<Map<String, dynamic>> 诊断报告
  static Future<Map<String, dynamic>> generateDiagnosticReport() async {
    debugPrint('📊 生成完整诊断报告...');
    
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
    };
    
    try {
      // 获取执行历史
      final executionHistory = await getExecutionHistory();
      report['executionHistory'] = {
        'totalExecutions': executionHistory.length,
        'successfulExecutions': executionHistory.where((e) => e.success).length,
        'failedExecutions': executionHistory.where((e) => !e.success).length,
        'recentExecutions': executionHistory.take(10).map((e) => e.toJson()).toList(),
      };
      
      // 检查当前系统状态
      final constraints = await checkSystemConstraints();
      report['currentSystemStatus'] = constraints.toJson();
      
      // 检查后台任务配置
      final taskStatus = await _channel.invokeMethod('checkBackgroundTaskStatus');
      report['backgroundTaskConfiguration'] = taskStatus;
      
      // 分析问题
      final issues = <String>[];
      final recommendations = <String>[];
      
      // 分析执行历史
      if (executionHistory.isEmpty) {
        issues.add('没有后台任务执行记录');
        recommendations.add('检查任务是否正确注册和调度');
      } else {
        final recentFailures = executionHistory.take(5).where((e) => !e.success).length;
        if (recentFailures >= 3) {
          issues.add('最近的后台任务执行失败率较高');
          recommendations.add('检查任务执行逻辑和错误日志');
        }
      }
      
      // 分析系统限制
      if (constraints.lowPowerModeEnabled) {
        issues.add('设备处于低电量模式');
        recommendations.add('关闭低电量模式或连接充电器');
      }
      
      if (!constraints.backgroundAppRefreshEnabled) {
        issues.add('后台应用刷新被禁用');
        recommendations.add('在设置中启用后台应用刷新');
      }
      
      if (constraints.batteryLevel < 20) {
        issues.add('设备电量较低');
        recommendations.add('为设备充电以提高后台任务执行概率');
      }
      
      report['analysis'] = {
        'issues': issues,
        'recommendations': recommendations,
      };
      
      debugPrint('✅ 诊断报告生成完成');
      
    } catch (e) {
      debugPrint('❌ 生成诊断报告失败: $e');
      report['error'] = e.toString();
    }
    
    return report;
  }
  
  /// 清除历史记录
  /// @return Future<void>
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_executionHistoryKey);
      await prefs.remove(_constraintHistoryKey);
      debugPrint('🗑️ 历史记录已清除');
    } catch (e) {
      debugPrint('❌ 清除历史记录失败: $e');
    }
  }
  
  /// 模拟后台任务执行（用于测试）
  /// @return Future<void>
  static Future<void> simulateBackgroundTaskExecution() async {
    debugPrint('🧪 模拟后台任务执行...');
    
    final startTime = DateTime.now();
    
    try {
      // 调用原生方法触发后台任务
      final result = await _channel.invokeMethod('triggerBackgroundTask');
      
      final endTime = DateTime.now();
      final executionTime = endTime.difference(startTime);
      
      await recordTaskExecution(
        taskType: 'simulated_background_task',
        success: result['success'] ?? false,
        executionTime: executionTime,
        additionalData: {
          'trigger_method': 'manual_simulation',
          'result': result,
        },
      );
      
      debugPrint('✅ 模拟后台任务执行完成，耗时: ${executionTime.inMilliseconds}ms');
      
    } catch (e) {
      final endTime = DateTime.now();
      final executionTime = endTime.difference(startTime);
      
      await recordTaskExecution(
        taskType: 'simulated_background_task',
        success: false,
        errorMessage: e.toString(),
        executionTime: executionTime,
      );
      
      debugPrint('❌ 模拟后台任务执行失败: $e');
    }
  }
}