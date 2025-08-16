import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/reminder_and_tips.dart';
import '../models/physical_activity.dart';
import '../services/database_service.dart';

class TipsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 10),
  ));
  
  List<UserTip> _todayTips = [];
  bool _isLoading = false;
  
  List<UserTip> get todayTips => _todayTips;
  bool get isLoading => _isLoading;

  Future<void> loadTodayTips(int userId) async {
    debugPrint('=== 开始加载用户推荐 ===');
    debugPrint('用户ID: $userId');
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _todayTips = await _databaseService.getTodayUserTips(userId);
      debugPrint('数据库中已有 ${_todayTips.length} 条今日推荐');
      
      // If no tips for today, generate some
      if (_todayTips.isEmpty) {
        debugPrint('今日暂无推荐，开始生成新推荐...');
        await _generateDailyTips(userId);
        _todayTips = await _databaseService.getTodayUserTips(userId);
        debugPrint('新生成并加载了 ${_todayTips.length} 条推荐');
      } else {
        debugPrint('加载了已有的 ${_todayTips.length} 条推荐');
      }
      
      // 打印推荐内容摘要
      for (int i = 0; i < _todayTips.length; i++) {
        final content = _todayTips[i].content;
        debugPrint('推荐 ${i + 1}: ${content.substring(0, content.length > 30 ? 30 : content.length)}...');
      }
      
      debugPrint('=== 推荐加载完成 ===');
    } catch (e) {
      debugPrint('=== 推荐加载失败 ===');
      debugPrint('错误详情: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _generateDailyTips(int userId) async {
    debugPrint('=== 开始生成每日推荐 ===');
    debugPrint('目标用户ID: $userId');
    
    try {
      List<String> tips;
      
      // Generate personalized tips using OpenAI API based on user's activity history
      debugPrint('调用 OpenAI API 生成个性化推荐...');
      tips = await _generateTipsWithOpenAI(userId);
      debugPrint('成功生成 ${tips.length} 条推荐');
      
      final today = DateTime.now();
      debugPrint('开始保存推荐到数据库，日期: ${today.toIso8601String()}');
      
      for (int i = 0; i < tips.length; i++) {
        final tipContent = tips[i];
        final tip = UserTip(
          userId: userId,
          tipDate: today,
          content: tipContent,
        );
        await _databaseService.insertUserTip(tip);
        debugPrint('已保存第 ${i + 1} 条推荐: ${tipContent.substring(0, tipContent.length > 50 ? 50 : tipContent.length)}...');
      }
      
      debugPrint('=== 每日推荐生成完成 ===');
    } catch (e) {
      debugPrint('=== 每日推荐生成失败 ===');
      debugPrint('错误详情: $e');
    }
  }

  Future<List<String>> _generateMockTips() async {
    // Mock health tips - in a real app, this would call OpenAI API
    final allTips = [
      'Stay hydrated by drinking at least 8 glasses of water throughout the day.',
      'Take a 5-minute break every hour to stretch and move around.',
      'Practice deep breathing exercises to reduce stress and improve focus.',
      'Get 7-9 hours of quality sleep each night for optimal recovery.',
      'Include protein in every meal to support muscle health and satiety.',
      'Take the stairs instead of the elevator when possible.',
      'Spend at least 10 minutes in natural sunlight daily for vitamin D.',
      'Practice good posture while sitting and standing.',
      'Eat a variety of colorful fruits and vegetables for essential nutrients.',
      'Limit screen time before bedtime to improve sleep quality.',
      'Do some form of physical activity for at least 30 minutes daily.',
      'Practice mindfulness or meditation for mental well-being.',
      'Keep healthy snacks like nuts and fruits readily available.',
      'Maintain social connections for emotional health.',
      'Listen to your body and rest when you feel tired.',
    ];
    
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return 3 random tips
    allTips.shuffle();
    return allTips.take(3).toList();
  }

  // This would be called by a background task at midnight
  Future<void> generateDailyTipsForAllUsers() async {
    try {
      // In a real app, you would:
      // 1. Get all active users from the database
      // 2. For each user, generate personalized tips using OpenAI
      // 3. Store the tips in the database
      
      debugPrint('Daily tips generation task executed at ${DateTime.now()}');
    } catch (e) {
      debugPrint('Error in daily tips generation task: $e');
    }
  }

  // OpenAI integration implementation
  Future<List<String>> _generateTipsWithOpenAI(int userId) async {
    debugPrint('=== OpenAI 推荐生成开始 ===');
    debugPrint('用户ID: $userId');
    
    try {
      // Get user's activity history for personalization
      debugPrint('正在获取用户最近20条运动记录...');
      final recentActivities = await _databaseService.getRecentActivityRecords(userId, limit: 20);
      debugPrint('获取到 ${recentActivities.length} 条运动记录');
      
      // Build detailed context for OpenAI based on user's recent activities
      String context = "Generate exactly 3 personalized health and fitness tips for a user based on their recent exercise patterns. ";
      
      if (recentActivities.isNotEmpty) {
        debugPrint('开始分析用户运动模式...');
        // Get activity details to build comprehensive context
        final activityMap = <int, List<ActivityRecord>>{};
        for (final record in recentActivities) {
          activityMap.putIfAbsent(record.activityTypeId, () => []).add(record);
        }
        debugPrint('运动类型统计: 共 ${activityMap.length} 种不同运动');
        
        // Get activity names and build frequency analysis
        final activityDetails = <String>[];
        for (final entry in activityMap.entries) {
          final activityTypeId = entry.key;
          final records = entry.value;
          final totalDuration = records.fold<int>(0, (sum, r) => sum + r.durationMinutes);
          final frequency = records.length;
          
          // Get activity name from database
          final activity = await _databaseService.getPhysicalActivityById(activityTypeId);
          final activityName = activity?.name ?? 'Unknown Activity';
          
          final detail = '$activityName (${frequency}次, 总计${totalDuration}分钟)';
          activityDetails.add(detail);
          debugPrint('  - $detail');
        }
        
        context += "用户最近的运动记录: ${activityDetails.join(', ')}. ";
        
        // Add specific guidance based on activity patterns
        final mostFrequentActivity = activityMap.entries
            .reduce((a, b) => a.value.length > b.value.length ? a : b);
        final mostFrequentActivityName = (await _databaseService.getPhysicalActivityById(mostFrequentActivity.key))?.name ?? 'Unknown';
        debugPrint('用户最频繁的运动: $mostFrequentActivityName (${mostFrequentActivity.value.length}次)');
        
        String specialGuidance = '';
        if (mostFrequentActivityName.contains('伸展') || mostFrequentActivityName.contains('拉伸')) {
          specialGuidance = "由于用户频繁进行伸展运动，请优先推送与脊柱健康、肌肉放松、姿势矫正相关的深度内容。";
          debugPrint('检测到伸展运动模式，将推送脊柱健康相关内容');
        } else if (mostFrequentActivityName.contains('跑步') || mostFrequentActivityName.contains('有氧')) {
          specialGuidance = "由于用户频繁进行有氧运动，请优先推送与心肺功能、耐力提升、运动恢复相关的内容。";
          debugPrint('检测到有氧运动模式，将推送心肺功能相关内容');
        } else if (mostFrequentActivityName.contains('力量') || mostFrequentActivityName.contains('举重')) {
          specialGuidance = "由于用户频繁进行力量训练，请优先推送与肌肉增长、蛋白质补充、训练计划相关的内容。";
          debugPrint('检测到力量训练模式，将推送肌肉增长相关内容');
        } else {
          debugPrint('未检测到特定运动模式，使用通用推荐策略');
        }
        context += specialGuidance;
      } else {
        context += "用户暂无运动记录，请提供通用的健康和运动入门建议。";
        debugPrint('用户无运动记录，将提供通用健康建议');
      }
      
      context += " 请确保建议实用、具体且有激励性。每条建议以数字开头(1., 2., 3.)，每行一条。";
      debugPrint('构建的提示词长度: ${context.length} 字符');
      debugPrint('提示词内容: $context');

      final apiKey = dotenv.env['OPENAI_API_KEY'];
      debugPrint('OpenAI API Key 状态: ${apiKey != null && apiKey.isNotEmpty ? "已配置" : "未配置"}');
      
      debugPrint('开始调用 OpenAI API...');
      try {
        final response = await _dio.post(
          'https://api.siliconflow.cn/v1/chat/completions',
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': 'Qwen/QwQ-32B',
            'messages': [
              {
                'role': 'system',
                'content': 'You are a helpful fitness and health coach. Provide practical, actionable health tips. Return exactly 3 tips, each on a new line, numbered 1., 2., 3.',
              },
              {
                'role': 'user',
                'content': context,
              },
            ],
            'max_tokens': 300,
            'temperature': 0.7,
          },
        );
        debugPrint('OpenAI API 调用成功，状态码: ${response.statusCode}');

        final content = response.data['choices'][0]['message']['content'] as String;
        debugPrint('OpenAI 返回内容: $content');
        
        // Parse the response to extract individual tips
        final tips = content.split('\n')
            .where((line) => line.trim().isNotEmpty && line.contains('.'))
            .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
            .take(3)
            .toList();
        
        debugPrint('解析出 ${tips.length} 条建议:');
        for (int i = 0; i < tips.length; i++) {
          debugPrint('  ${i + 1}. ${tips[i]}');
        }

        // Ensure we have exactly 3 tips
        if (tips.length < 3) {
          debugPrint('OpenAI 返回的建议少于3条，回退到模拟建议');
          return await _generateMockTips();
        }

        debugPrint('=== OpenAI 推荐生成成功 ===');
        return tips;
      } catch (e) {
        debugPrint('=== OpenAI 推荐生成失败 ===');
        debugPrint('错误详情: $e');
        if (e is DioException) {
          debugPrint('网络错误类型: ${e.type}');
          debugPrint('错误消息: ${e.message}');
          if (e.response != null) {
            debugPrint('响应状态码: ${e.response?.statusCode}');
            debugPrint('响应数据: ${e.response?.data}');
          }
        }
        debugPrint('回退到模拟建议生成');
        return await _generateMockTips();
      }
    } catch (e) {
      debugPrint('=== OpenAI 推荐生成过程中发生未预期错误 ===');
      debugPrint('错误详情: $e');
      debugPrint('回退到模拟建议生成');
      return await _generateMockTips();
    }
  }
}
