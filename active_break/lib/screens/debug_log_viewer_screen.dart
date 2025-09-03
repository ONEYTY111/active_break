/**
 * 调试日志查看界面
 * @Description: 提供应用内日志查看功能，让用户能够直接查看调试信息
 * @author Author
 * @date Current date and time
 * @company: 西安博达软件股份有限公司
 * @copyright: Copyright (c) 2025
 * @version V1.0
 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/reminder_debug_helper.dart';
import '../utils/background_task_debugger.dart';
import '../providers/activity_provider.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

/**
 * 调试日志查看界面类
 * @Description: 显示调试日志和提供调试操作的界面
 * @author Author
 * @date Current date and time
 */
class DebugLogViewerScreen extends StatefulWidget {
  const DebugLogViewerScreen({Key? key}) : super(key: key);

  @override
  State<DebugLogViewerScreen> createState() => _DebugLogViewerScreenState();
}

/**
 * 调试日志查看界面状态类
 * @Description: 管理调试日志界面的状态和交互
 * @author Author
 * @date Current date and time
 */
class _DebugLogViewerScreenState extends State<DebugLogViewerScreen> {
  final List<String> _debugLogs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isRunningDiagnostic = false;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _addLog('调试日志查看器已启动');
    _addLog('点击下方按钮开始调试5分钟提醒功能');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /**
   * 添加日志条目
   * @author Author
   * @date Current date and time
   * @param message 日志消息
   * @return void
   */
  void _addLog(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _debugLogs.add('[$timestamp] $message');
    });

    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /**
   * 清空日志
   * @author Author
   * @date Current date and time
   * @return void
   */
  void _clearLogs() {
    setState(() {
      _debugLogs.clear();
    });
    _addLog('日志已清空');
  }

  /**
   * 复制日志到剪贴板
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  Future<void> _copyLogsToClipboard() async {
    final logsText = _debugLogs.join('\n');
    await Clipboard.setData(ClipboardData(text: logsText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日志已复制到剪贴板'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /**
   * 运行完整诊断
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  Future<void> _runFullDiagnostic() async {
    if (_isRunningDiagnostic) return;

    setState(() {
      _isRunningDiagnostic = true;
    });

    _addLog('=== 开始运行完整诊断 ===');

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId ?? 1;

      _addLog('用户ID: $userId');

      // 重定向debugPrint输出到我们的日志
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addLog(message);
        }
        originalDebugPrint?.call(message, wrapWidth: wrapWidth);
      };

      await ReminderDebugHelper.runFullDiagnostic(userId);

      // 恢复原始debugPrint
      debugPrint = originalDebugPrint;

      _addLog('=== 完整诊断已完成 ===');
    } catch (e, stackTrace) {
      _addLog('❌ 诊断过程中发生错误: $e');
      _addLog('错误堆栈: $stackTrace');
    } finally {
      setState(() {
        _isRunningDiagnostic = false;
      });
    }
  }

  /**
   * 创建5分钟测试提醒
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  Future<void> _create5MinuteTestReminder() async {
    _addLog('=== 创建5分钟测试提醒 ===');

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId ?? 1;

      // 重定向debugPrint输出
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addLog(message);
        }
        originalDebugPrint?.call(message, wrapWidth: wrapWidth);
      };

      await ReminderDebugHelper.create5MinuteTestReminder(userId);

      // 恢复原始debugPrint
      debugPrint = originalDebugPrint;

      _addLog('=== 5分钟测试提醒创建完成 ===');
    } catch (e, stackTrace) {
      _addLog('❌ 创建测试提醒时发生错误: $e');
      _addLog('错误堆栈: $stackTrace');
    }
  }

  /**
   * 清理测试数据
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  Future<void> _cleanupTestData() async {
    _addLog('=== 清理测试数据 ===');

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.userId ?? 1;

      // 重定向debugPrint输出
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addLog(message);
        }
        originalDebugPrint?.call(message, wrapWidth: wrapWidth);
      };

      await ReminderDebugHelper.cleanupTestData(userId);

      // 恢复原始debugPrint
      debugPrint = originalDebugPrint;

      _addLog('=== 测试数据清理完成 ===');
    } catch (e, stackTrace) {
      _addLog('❌ 清理测试数据时发生错误: $e');
      _addLog('错误堆栈: $stackTrace');
    }
  }

  /**
   * 检查iOS后台任务状态
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  Future<void> _checkBackgroundTaskStatus() async {
    _addLog('=== 检查iOS后台任务状态 ===');

    try {
      final result = await BackgroundTaskDebugger.checkBackgroundTaskStatus();
      _addLog('后台任务状态检查结果: $result');
    } catch (e, stackTrace) {
      _addLog('❌ 检查后台任务状态时发生错误: $e');
      _addLog('错误堆栈: $stackTrace');
    }
  }

  /**
   * 手动触发后台任务
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  Future<void> _triggerBackgroundTask() async {
    _addLog('=== 手动触发后台任务 ===');

    try {
      final result = await BackgroundTaskDebugger.triggerBackgroundTask();
      _addLog('手动触发后台任务结果: $result');
    } catch (e, stackTrace) {
      _addLog('❌ 手动触发后台任务时发生错误: $e');
      _addLog('错误堆栈: $stackTrace');
    }
  }

  /**
   * 运行完整的后台任务诊断
   * @author Author
   * @date Current date and time
   * @return Future<void>
   */
  Future<void> _runBackgroundTaskDiagnostic() async {
    _addLog('=== 开始后台任务完整诊断 ===');

    try {
      // 重定向debugPrint输出
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          _addLog(message);
        }
        originalDebugPrint?.call(message, wrapWidth: wrapWidth);
      };

      await BackgroundTaskDebugger.performFullDiagnostic();

      // 恢复原始debugPrint
      debugPrint = originalDebugPrint;

      _addLog('=== 后台任务完整诊断完成 ===');
    } catch (e, stackTrace) {
      _addLog('❌ 后台任务诊断时发生错误: $e');
      _addLog('错误堆栈: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志查看器'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll
                  ? Icons.vertical_align_bottom
                  : Icons.vertical_align_center,
            ),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
              _addLog(_autoScroll ? '已开启自动滚动' : '已关闭自动滚动');
            },
            tooltip: _autoScroll ? '关闭自动滚动' : '开启自动滚动',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: '复制日志',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 日志显示区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey[50],
              ),
              child: _debugLogs.isEmpty
                  ? const Center(
                      child: Text(
                        '暂无日志\n点击下方按钮开始调试',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _debugLogs.length,
                      itemBuilder: (context, index) {
                        final log = _debugLogs[index];
                        Color textColor = Colors.black87;

                        // 根据日志内容设置颜色
                        if (log.contains('❌') ||
                            log.contains('✗') ||
                            log.contains('失败') ||
                            log.contains('错误')) {
                          textColor = Colors.red[700]!;
                        } else if (log.contains('✅') ||
                            log.contains('✓') ||
                            log.contains('成功') ||
                            log.contains('完成')) {
                          textColor = Colors.green[700]!;
                        } else if (log.contains('⚠️') ||
                            log.contains('警告') ||
                            log.contains('注意')) {
                          textColor = Colors.orange[700]!;
                        } else if (log.contains('===')) {
                          textColor = Colors.blue[700]!;
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // 操作按钮区域
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isRunningDiagnostic
                            ? null
                            : _runFullDiagnostic,
                        icon: _isRunningDiagnostic
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.bug_report),
                        label: Text(_isRunningDiagnostic ? '诊断中...' : '运行完整诊断'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _create5MinuteTestReminder,
                        icon: const Icon(Icons.timer),
                        label: const Text('创建5分钟测试提醒'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _cleanupTestData,
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('清理测试数据'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _runBackgroundTaskDiagnostic,
                        icon: const Icon(Icons.task_alt),
                        label: const Text('后台任务诊断'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _checkBackgroundTaskStatus,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('检查后台状态'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _triggerBackgroundTask,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('手动触发后台任务'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Text(
                    '💡 使用说明：\n'
                    '1. 点击"运行完整诊断"检查提醒功能状态\n'
                    '2. 点击"创建5分钟测试提醒"创建测试用的提醒设置\n'
                    '3. 点击"后台任务诊断"检查iOS后台任务状态\n'
                    '4. 点击"手动触发后台任务"测试后台任务执行\n'
                    '5. 观察日志输出，查看详细的调试信息',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
