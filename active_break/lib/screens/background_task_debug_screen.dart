/// 后台任务调试界面
/// 
/// 提供全面的iOS后台任务调试功能，包括：
/// - 系统限制检查
/// - 任务执行历史
/// - 实时监控
/// - 手动触发测试
/// 
/// @author Assistant
/// @date 2024-01-22
/// @company 西安博达软件股份有限公司
/// @copyright Copyright (c) 2024
/// @version V1.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../utils/comprehensive_background_debugger.dart';

/// 后台任务调试界面
class BackgroundTaskDebugScreen extends StatefulWidget {
  const BackgroundTaskDebugScreen({Key? key}) : super(key: key);

  @override
  State<BackgroundTaskDebugScreen> createState() => _BackgroundTaskDebugScreenState();
}

/// 后台任务调试界面状态类
class _BackgroundTaskDebugScreenState extends State<BackgroundTaskDebugScreen> {
  /// 系统限制检查结果
  SystemConstraintCheck? _systemConstraints;
  
  /// 任务执行历史
  List<BackgroundTaskExecution> _executionHistory = [];
  
  /// 是否正在加载
  bool _isLoading = false;
  
  /// 自动刷新定时器
  Timer? _refreshTimer;
  
  /// 是否启用自动刷新
  bool _autoRefreshEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// 加载初始数据
  /// @throws Exception 加载失败时抛出异常
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _checkSystemConstraints(),
        _loadExecutionHistory(),
      ]);
    } catch (e) {
      _showErrorSnackBar('加载数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 检查系统限制
  /// @throws Exception 检查失败时抛出异常
  Future<void> _checkSystemConstraints() async {
    try {
      final constraints = await ComprehensiveBackgroundDebugger.checkSystemConstraints();
      setState(() {
        _systemConstraints = constraints;
      });
    } catch (e) {
      debugPrint('检查系统限制失败: $e');
      rethrow;
    }
  }

  /// 加载执行历史
  /// @throws Exception 加载失败时抛出异常
  Future<void> _loadExecutionHistory() async {
    try {
      final history = await ComprehensiveBackgroundDebugger.getExecutionHistory();
      setState(() {
        _executionHistory = history;
      });
    } catch (e) {
      debugPrint('加载执行历史失败: $e');
      rethrow;
    }
  }

  /// 手动触发后台任务
  /// @throws Exception 触发失败时抛出异常
  Future<void> _triggerBackgroundTask() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 使用原生方法通道直接触发后台任务
      const platform = MethodChannel('com.activebreak/background_reminder');
      final result = await platform.invokeMethod('triggerBackgroundTask');
      
      if (result['success'] == true) {
        _showSuccessSnackBar('后台任务触发成功');
        // 记录手动触发的执行
        await ComprehensiveBackgroundDebugger.recordTaskExecution(
          taskType: 'manual_trigger',
          success: true,
          additionalData: {'trigger_time': DateTime.now().toIso8601String()},
        );
        // 延迟刷新执行历史
        await Future.delayed(const Duration(seconds: 2));
        await _loadExecutionHistory();
      } else {
        _showErrorSnackBar('后台任务触发失败: ${result['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('触发后台任务失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 执行完整诊断
  /// @throws Exception 诊断失败时抛出异常
  Future<void> _runFullDiagnostic() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 执行系统限制检查
      final constraints = await ComprehensiveBackgroundDebugger.checkSystemConstraints();
      final history = await ComprehensiveBackgroundDebugger.getExecutionHistory();
      
      // 生成诊断报告
      final report = _generateDiagnosticReport(constraints, history);
      
      // 显示诊断报告对话框
      _showDiagnosticReport(report);
      
      // 刷新数据
      await _loadInitialData();
    } catch (e) {
      _showErrorSnackBar('执行诊断失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 生成诊断报告
  /// @param constraints 系统限制检查结果
  /// @param history 执行历史
  /// @return Map<String, dynamic> 诊断报告
  Map<String, dynamic> _generateDiagnosticReport(SystemConstraintCheck constraints, List<BackgroundTaskExecution> history) {
    final issues = <String>[];
    final recommendations = <String>[];
    
    // 检查系统限制
    if (!constraints.backgroundAppRefreshEnabled) {
      issues.add('后台应用刷新被禁用');
      recommendations.add('请在设置中启用后台应用刷新');
    }
    
    if (constraints.lowPowerModeEnabled) {
      issues.add('低电量模式已启用');
      recommendations.add('低电量模式会限制后台任务执行');
    }
    
    if (constraints.batteryLevel < 20 && !constraints.isCharging) {
      issues.add('电池电量低且未充电');
      recommendations.add('iOS在低电量时会限制后台任务');
    }
    
    // 检查执行历史
    if (history.isEmpty) {
      issues.add('没有任何后台任务执行记录');
      recommendations.add('这表明后台任务可能从未被系统调用');
    } else {
      final recentFailures = history.take(5).where((e) => !e.success).length;
      if (recentFailures > 2) {
        issues.add('最近的后台任务执行失败率较高');
        recommendations.add('检查任务逻辑是否存在问题');
      }
    }
    
    final systemStatus = issues.isEmpty ? '良好' : '存在问题';
    
    return {
      'timestamp': DateTime.now().toString(),
      'systemStatus': systemStatus,
      'issues': issues,
      'recommendations': recommendations.join('\n'),
      'details': '检查项目:\n'
          '- 后台应用刷新: ${constraints.backgroundAppRefreshEnabled ? "已启用" : "已禁用"}\n'
          '- 低电量模式: ${constraints.lowPowerModeEnabled ? "已启用" : "未启用"}\n'
          '- 电池电量: ${constraints.batteryLevel}%\n'
          '- 执行历史记录: ${history.length}条',
    };
  }

  /// 切换自动刷新
  void _toggleAutoRefresh() {
    setState(() {
      _autoRefreshEnabled = !_autoRefreshEnabled;
    });

    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _loadInitialData();
      });
    } else {
      _refreshTimer?.cancel();
    }
  }

  /// 显示诊断报告对话框
  /// @param report 诊断报告
  void _showDiagnosticReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('诊断报告'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('诊断时间: ${report['timestamp']}'),
              const SizedBox(height: 16),
              Text('系统状态: ${report['systemStatus']}'),
              const SizedBox(height: 8),
              Text('建议: ${report['recommendations']}'),
              const SizedBox(height: 16),
              const Text('详细信息:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(report['details'] ?? '无详细信息'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示成功提示
  /// @param message 提示消息
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 显示错误提示
  /// @param message 错误消息
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('后台任务调试'),
        actions: [
          IconButton(
            icon: Icon(_autoRefreshEnabled ? Icons.pause : Icons.play_arrow),
            onPressed: _toggleAutoRefresh,
            tooltip: _autoRefreshEnabled ? '停止自动刷新' : '开启自动刷新',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadInitialData,
            tooltip: '手动刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSystemConstraintsCard(),
                    const SizedBox(height: 16),
                    _buildActionButtonsCard(),
                    const SizedBox(height: 16),
                    _buildExecutionHistoryCard(),
                  ],
                ),
              ),
            ),
    );
  }

  /// 构建系统限制检查卡片
  /// @return Widget 系统限制检查卡片组件
  Widget _buildSystemConstraintsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '系统限制检查',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_systemConstraints != null) ...
              _buildConstraintItems(_systemConstraints!)
            else
              const Text('暂无系统限制信息'),
          ],
        ),
      ),
    );
  }

  /// 构建限制条件项目列表
  /// @param constraints 系统限制检查结果
  /// @return List<Widget> 限制条件项目组件列表
  List<Widget> _buildConstraintItems(SystemConstraintCheck constraints) {
    return [
      _buildConstraintItem(
        '低电量模式',
        constraints.lowPowerModeEnabled ? '已启用' : '未启用',
        constraints.lowPowerModeEnabled ? Colors.orange : Colors.green,
      ),
      _buildConstraintItem(
        '电池电量',
        '${constraints.batteryLevel}%',
        constraints.batteryLevel < 20 ? Colors.red : Colors.green,
      ),
      _buildConstraintItem(
        '充电状态',
        constraints.isCharging ? '充电中' : '未充电',
        constraints.isCharging ? Colors.green : Colors.grey,
      ),
      _buildConstraintItem(
        '后台应用刷新',
        constraints.backgroundAppRefreshEnabled ? '已启用' : '已禁用',
        constraints.backgroundAppRefreshEnabled ? Colors.green : Colors.red,
      ),
      _buildConstraintItem(
        '设备型号',
        constraints.deviceModel,
        Colors.blue,
      ),
      _buildConstraintItem(
        'iOS版本',
        constraints.iosVersion,
        Colors.blue,
      ),
    ];
  }

  /// 构建单个限制条件项目
  /// @param label 标签
  /// @param value 值
  /// @param color 颜色
  /// @return Widget 限制条件项目组件
  Widget _buildConstraintItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建操作按钮卡片
  /// @return Widget 操作按钮卡片组件
  Widget _buildActionButtonsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '调试操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _triggerBackgroundTask,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('手动触发任务'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runFullDiagnostic,
                    icon: const Icon(Icons.medical_services),
                    label: const Text('完整诊断'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建执行历史卡片
  /// @return Widget 执行历史卡片组件
  Widget _buildExecutionHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '执行历史',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '共 ${_executionHistory.length} 条记录',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_executionHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    '暂无执行记录\n\n这可能说明后台任务从未被系统调用过',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._executionHistory.take(10).map((execution) => _buildExecutionItem(execution)),
          ],
        ),
      ),
    );
  }

  /// 构建执行记录项目
  /// @param execution 执行记录
  /// @return Widget 执行记录项目组件
  Widget _buildExecutionItem(BackgroundTaskExecution execution) {
    final statusColor = execution.success ? Colors.green : Colors.red;
    final statusIcon = execution.success ? Icons.check_circle : Icons.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                execution.taskType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                _formatDateTime(execution.timestamp),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          if (execution.executionTime != null) ...[
            const SizedBox(height: 4),
            Text(
              '执行时长: ${execution.executionTime!.inSeconds}秒',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          if (execution.errorMessage != null && execution.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '错误: ${execution.errorMessage}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  /// 格式化日期时间
  /// @param dateTime 日期时间
  /// @return String 格式化后的日期时间字符串
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
  }
}