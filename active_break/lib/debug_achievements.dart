import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/user_provider.dart';
import 'services/achievement_service.dart';
import 'utils/app_localizations.dart';

class DebugAchievementsScreen extends StatefulWidget {
  const DebugAchievementsScreen({Key? key}) : super(key: key);

  @override
  State<DebugAchievementsScreen> createState() => _DebugAchievementsScreenState();
}

class _DebugAchievementsScreenState extends State<DebugAchievementsScreen> {
  final AchievementService _achievementService = AchievementService();
  String _debugOutput = '';

  void _addDebugOutput(String message) {
    setState(() {
      _debugOutput += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
  }

  Future<void> _resetAchievements() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
    
    if (userProvider.currentUser == null) {
      _addDebugOutput('错误: 用户未登录');
      return;
    }
    
    try {
      await _achievementService.resetUserAchievements(userProvider.currentUser!.userId!);
      await achievementProvider.refresh();
      _addDebugOutput('成就已重置');
    } catch (e) {
      _addDebugOutput('重置失败: $e');
    }
  }

  Future<void> _checkAchievements() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final achievementProvider = Provider.of<AchievementProvider>(context, listen: false);
    
    if (userProvider.currentUser == null) {
      _addDebugOutput('错误: 用户未登录');
      return;
    }
    
    try {
      _addDebugOutput('开始检查成就...');
      final newAchievements = await achievementProvider.checkAchievementsAfterCheckin(context);
      _addDebugOutput('检查完成，新达成成就数: ${newAchievements.length}');
      for (final achievement in newAchievements) {
        _addDebugOutput('新达成: ${achievement.name}');
      }
    } catch (e) {
      _addDebugOutput('检查失败: $e');
    }
  }

  Future<void> _showUserStats() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (userProvider.currentUser == null) {
      _addDebugOutput('错误: 用户未登录');
      return;
    }
    
    try {
      final userId = userProvider.currentUser!.userId!;
      final checkinCount = await _achievementService.getCheckinCount(userId);
      final exerciseCount = await _achievementService.getExerciseCount(userId);
      
      _addDebugOutput('用户统计:');
      _addDebugOutput('  打卡次数: $checkinCount');
      _addDebugOutput('  运动次数: $exerciseCount');
    } catch (e) {
      _addDebugOutput('获取统计失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成就调试工具'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetAchievements,
                    child: const Text('重置成就'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkAchievements,
                    child: const Text('检查成就'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showUserStats,
                    child: const Text('显示统计'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _debugOutput = '';
                      });
                    },
                    child: const Text('清空日志'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '调试输出:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput.isEmpty ? '暂无输出' : _debugOutput,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}