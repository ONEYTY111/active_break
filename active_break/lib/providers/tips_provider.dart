import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    debugPrint('=== Starting to load user recommendations ===');
    debugPrint('User ID: $userId');
    
    _isLoading = true;
    notifyListeners();
    
    try {
      _todayTips = await _databaseService.getTodayUserTips(userId);
      debugPrint('Found ${_todayTips.length} existing recommendations in database');
      
      // If no tips for today, generate some
      if (_todayTips.isEmpty) {
        debugPrint('No recommendations for today, generating new ones...');
        await _generateDailyTips(userId);
        _todayTips = await _databaseService.getTodayUserTips(userId);
        debugPrint('Generated and loaded ${_todayTips.length} new recommendations');
      } else {
        debugPrint('Loaded ${_todayTips.length} existing recommendations');
      }
      
      // Print recommendation content summary
      for (int i = 0; i < _todayTips.length; i++) {
        final content = _todayTips[i].content;
        debugPrint('Recommendation ${i + 1}: ${content.substring(0, content.length > 30 ? 30 : content.length)}...');
      }
      
      debugPrint('=== Recommendations loading completed ===');
    } catch (e) {
      debugPrint('=== Recommendations loading failed ===');
      debugPrint('Error details: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _generateDailyTips(int userId) async {
    debugPrint('=== Starting to generate daily recommendations ===');
    debugPrint('Target user ID: $userId');
    
    try {
      List<String> tips;
      
      // Generate personalized tips using OpenAI API based on user's activity history
      debugPrint('Calling OpenAI API to generate personalized recommendations...');
      tips = await _generateTipsWithOpenAI(userId);
      debugPrint('Successfully generated ${tips.length} recommendations');
      
      final today = DateTime.now();
      debugPrint('Starting to save recommendations to database, date: ${today.toIso8601String()}');
      
      for (int i = 0; i < tips.length; i++) {
        final tipContent = tips[i];
        final tip = UserTip(
          userId: userId,
          tipDate: today,
          content: tipContent,
        );
        await _databaseService.insertUserTip(tip);
        debugPrint('Saved recommendation ${i + 1}: ${tipContent.substring(0, tipContent.length > 50 ? 50 : tipContent.length)}...');
      }
      
      debugPrint('=== Daily recommendations generation completed ===');
    } catch (e) {
      debugPrint('=== Daily recommendations generation failed ===');
      debugPrint('Error details: $e');
    }
  }

  Future<List<String>> _generateMockTips() async {
    // Get current language from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    
    // Mock health tips based on language
    final Map<String, List<String>> tipsByLanguage = {
      'zh': [
        '每天至少喝8杯水，保持充足的水分摄入。',
        '每小时起身活动5分钟，伸展身体缓解疲劳。',
        '练习深呼吸，减轻压力并提高专注力。',
        '确保每晚7-9小时的优质睡眠，促进身体恢复。',
        '每餐都要包含蛋白质，支持肌肉健康和饱腹感。',
        '尽可能选择爬楼梯而不是乘电梯。',
        '每天至少晒10分钟太阳，补充维生素D。',
        '坐立时保持良好姿势，避免驼背。',
        '多吃各种颜色的水果和蔬菜，获取必需营养素。',
        '睡前限制屏幕时间，改善睡眠质量。',
        '每天至少进行30分钟的体育活动。',
        '练习正念冥想，促进心理健康。',
        '随时准备健康零食，如坚果和水果。',
        '保持良好的社交关系，促进情感健康。',
        '倾听身体信号，感到疲劳时及时休息。',
      ],
      'en': [
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
      ],
    };
    
    final allTips = tipsByLanguage[languageCode] ?? tipsByLanguage['zh']!;
    
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

  /**
   * 强制刷新今日推荐内容
   * 当用户切换语言时调用此方法，清除今日缓存的推荐并重新生成
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<void> 无返回值
   * @throws Exception 当数据库操作或API调用失败时抛出异常
   */
  Future<void> forceRefreshTodayTips(int userId) async {
    debugPrint('=== Force refreshing today\'s tips for language change ===');
    debugPrint('User ID: $userId');
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Clear today's tips from database
      debugPrint('Clearing today\'s tips from database...');
      await _databaseService.deleteTodayUserTips(userId);
      debugPrint('Today\'s tips cleared successfully');
      
      // Clear local cache
      _todayTips.clear();
      debugPrint('Local tips cache cleared');
      
      // Generate new tips with current language
      debugPrint('Generating new tips with current language...');
      await _generateDailyTips(userId);
      
      // Reload tips from database
      _todayTips = await _databaseService.getTodayUserTips(userId);
      debugPrint('Reloaded ${_todayTips.length} new tips');
      
      debugPrint('=== Force refresh completed successfully ===');
    } catch (e) {
      debugPrint('=== Force refresh failed ===');
      debugPrint('Error details: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /**
   * 使用OpenAI API生成个性化健康建议
   * @author Author
   * @date Current date and time
   * @param userId 用户ID
   * @return Future<List<String>> 返回3条健康建议列表
   * @throws Exception 当API调用失败时抛出异常
   */
  Future<List<String>> _generateTipsWithOpenAI(int userId) async {
    debugPrint('=== OpenAI recommendation generation started ===');
    debugPrint('User ID: $userId');
    
    try {
      // Get current language from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      debugPrint('Current language code: $languageCode');
      
      // Get user's activity history for personalization
      debugPrint('Fetching user\'s recent 20 activity records...');
      final recentActivities = await _databaseService.getRecentActivityRecords(userId, limit: 20);
      debugPrint('Retrieved ${recentActivities.length} activity records');
      
      // Build detailed context for OpenAI based on user's recent activities and language
      String context;
      if (languageCode == 'zh') {
        context = "请根据用户的运动模式，生成3条个性化的健康和健身建议。请用中文回复。";
      } else {
        context = "Generate exactly 3 personalized health and fitness tips for a user based on their recent exercise patterns. Please reply in English.";
      }
      
      if (recentActivities.isNotEmpty) {
        debugPrint('Starting to analyze user activity patterns...');
        // Get activity details to build comprehensive context
        final activityMap = <int, List<ActivityRecord>>{};
        for (final record in recentActivities) {
          activityMap.putIfAbsent(record.activityTypeId, () => []).add(record);
        }
        debugPrint('Activity type statistics: ${activityMap.length} different activities');
        
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
          
          final detail = '$activityName (${frequency} times, total ${totalDuration} minutes)';
          activityDetails.add(detail);
          debugPrint('  - $detail');
        }
        
        if (languageCode == 'zh') {
          context += "用户最近的运动记录：${activityDetails.join('，')}。";
        } else {
          context += "User's recent exercise records: ${activityDetails.join(', ')}. ";
        }
        
        // Add specific guidance based on activity patterns
        final mostFrequentActivity = activityMap.entries
            .reduce((a, b) => a.value.length > b.value.length ? a : b);
        final mostFrequentActivityName = (await _databaseService.getPhysicalActivityById(mostFrequentActivity.key))?.name ?? 'Unknown';
        debugPrint('User\'s most frequent activity: $mostFrequentActivityName (${mostFrequentActivity.value.length} times)');
        
        String specialGuidance = '';
        if (mostFrequentActivityName.toLowerCase().contains('stretch') || mostFrequentActivityName.toLowerCase().contains('flexibility')) {
          if (languageCode == 'zh') {
            specialGuidance = "由于用户经常进行拉伸运动，请优先推荐脊椎健康、肌肉放松和姿势矫正相关的内容。";
          } else {
            specialGuidance = "Since the user frequently performs stretching exercises, prioritize content related to spinal health, muscle relaxation, and posture correction.";
          }
          debugPrint('Detected stretching pattern, will recommend spinal health content');
        } else if (mostFrequentActivityName.toLowerCase().contains('running') || mostFrequentActivityName.toLowerCase().contains('cardio') || mostFrequentActivityName.toLowerCase().contains('aerobic')) {
          if (languageCode == 'zh') {
            specialGuidance = "由于用户经常进行有氧运动，请优先推荐心血管功能、耐力提升和运动恢复相关的内容。";
          } else {
            specialGuidance = "Since the user frequently performs aerobic exercises, prioritize content related to cardiovascular function, endurance improvement, and exercise recovery.";
          }
          debugPrint('Detected aerobic exercise pattern, will recommend cardiovascular content');
        } else if (mostFrequentActivityName.toLowerCase().contains('strength') || mostFrequentActivityName.toLowerCase().contains('weight') || mostFrequentActivityName.toLowerCase().contains('resistance')) {
          if (languageCode == 'zh') {
            specialGuidance = "由于用户经常进行力量训练，请优先推荐肌肉增长、蛋白质补充和训练计划相关的内容。";
          } else {
            specialGuidance = "Since the user frequently performs strength training, prioritize content related to muscle growth, protein supplementation, and training plans.";
          }
          debugPrint('Detected strength training pattern, will recommend muscle growth content');
        } else {
          debugPrint('No specific exercise pattern detected, using general recommendation strategy');
        }
        context += specialGuidance;
      } else {
        if (languageCode == 'zh') {
          context += "用户没有运动记录，请提供一般的健康和运动入门建议。";
        } else {
          context += "User has no activity records, please provide general health and exercise beginner advice.";
        }
        debugPrint('User has no activity records, will provide general health advice');
      }
      
      // Add final instructions based on language
      if (languageCode == 'zh') {
        context += "请确保建议实用、具体且有激励性。每条建议都应以数字开头（1.、2.、3.），每行一条。";
      } else {
        context += " Please ensure the advice is practical, specific, and motivational. Each suggestion should start with a number (1., 2., 3.), one per line.";
      }
      debugPrint('Built prompt length: ${context.length} characters');
      debugPrint('Prompt content: $context');

      final apiKey = dotenv.env['OPENAI_API_KEY'];
      debugPrint('OpenAI API Key status: ${apiKey != null && apiKey.isNotEmpty ? "Configured" : "Not configured"}');
      
      debugPrint('Starting OpenAI API call...');
      try {
        // Build system message based on language
        String systemMessage;
        if (languageCode == 'zh') {
          systemMessage = '你是一位专业的健身和健康教练。请提供实用、可操作的健康建议。请准确返回3条建议，每条建议单独一行，以数字编号（1.、2.、3.）。请用中文回复。';
        } else {
          systemMessage = 'You are a helpful fitness and health coach. Provide practical, actionable health tips. Return exactly 3 tips, each on a new line, numbered 1., 2., 3. Please reply in English.';
        }
        
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
                'content': systemMessage,
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
        debugPrint('OpenAI API call successful, status code: ${response.statusCode}');

        final content = response.data['choices'][0]['message']['content'] as String;
        debugPrint('OpenAI returned content: $content');
        
        // Parse the response to extract individual tips
        final tips = content.split('\n')
            .where((line) => line.trim().isNotEmpty && line.contains('.'))
            .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
            .take(3)
            .toList();
        
        debugPrint('Parsed ${tips.length} suggestions:');
        for (int i = 0; i < tips.length; i++) {
          debugPrint('  ${i + 1}. ${tips[i]}');
        }

        // Ensure we have exactly 3 tips
        if (tips.length < 3) {
          debugPrint('OpenAI returned less than 3 suggestions, falling back to simulated suggestions');
          return await _generateMockTips();
        }

        debugPrint('=== OpenAI recommendation generation successful ===');
        return tips;
      } catch (e) {
        debugPrint('=== OpenAI recommendation generation failed ===');
        debugPrint('Error details: $e');
        if (e is DioException) {
          debugPrint('Network error type: ${e.type}');
          debugPrint('Error message: ${e.message}');
          if (e.response != null) {
            debugPrint('Response status code: ${e.response?.statusCode}');
          debugPrint('Response data: ${e.response?.data}');
          }
        }
        debugPrint('Falling back to simulated suggestion generation');
        return await _generateMockTips();
      }
    } catch (e) {
      debugPrint('=== Unexpected error occurred during OpenAI recommendation generation ===');
      debugPrint('Error details: $e');
      debugPrint('Falling back to simulated suggestion generation');
      return await _generateMockTips();
    }
  }
}
