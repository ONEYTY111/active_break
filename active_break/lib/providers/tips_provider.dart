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
    final languageCode = prefs.getString('language_code') ?? 'zh';
    
    // Mock health tips based on language
    final Map<String, List<String>> tipsByLanguage = {
      'zh': [
        'Drink at least 8 glasses of water daily to maintain adequate hydration.',
        'Stand up and move for 5 minutes every hour to stretch and relieve fatigue.',
        'Practice deep breathing exercises to reduce stress and improve focus.',
        'Ensure 7-9 hours of quality sleep each night to promote body recovery.',
        'Include protein in every meal to support muscle health and satiety.',
        'Choose stairs over elevators whenever possible.',
        'Get at least 10 minutes of natural sunlight daily to supplement vitamin D.',
        'Maintain good posture when sitting and standing, avoid slouching.',
        'Eat a variety of colorful fruits and vegetables to get essential nutrients.',
        'Limit screen time before bed to improve sleep quality.',
        'Engage in at least 30 minutes of physical activity daily.',
        'Practice mindfulness meditation to promote mental health.',
        'Keep healthy snacks like nuts and fruits readily available.',
        'Maintain good social relationships to promote emotional health.',
        'Listen to your body signals and rest when feeling fatigued.',
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

  // OpenAI integration implementation
  Future<List<String>> _generateTipsWithOpenAI(int userId) async {
    debugPrint('=== OpenAI recommendation generation started ===');
    debugPrint('User ID: $userId');
    
    try {
      // Get user's activity history for personalization
      debugPrint('Fetching user\'s recent 20 activity records...');
      final recentActivities = await _databaseService.getRecentActivityRecords(userId, limit: 20);
      debugPrint('Retrieved ${recentActivities.length} activity records');
      
      // Build detailed context for OpenAI based on user's recent activities
      String context = "Generate exactly 3 personalized health and fitness tips for a user based on their recent exercise patterns. ";
      
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
        
        context += "User's recent exercise records: ${activityDetails.join(', ')}. ";
        
        // Add specific guidance based on activity patterns
        final mostFrequentActivity = activityMap.entries
            .reduce((a, b) => a.value.length > b.value.length ? a : b);
        final mostFrequentActivityName = (await _databaseService.getPhysicalActivityById(mostFrequentActivity.key))?.name ?? 'Unknown';
        debugPrint('User\'s most frequent activity: $mostFrequentActivityName (${mostFrequentActivity.value.length} times)');
        
        String specialGuidance = '';
        if (mostFrequentActivityName.toLowerCase().contains('stretch') || mostFrequentActivityName.toLowerCase().contains('flexibility')) {
        specialGuidance = "Since the user frequently performs stretching exercises, prioritize content related to spinal health, muscle relaxation, and posture correction.";
        debugPrint('Detected stretching pattern, will recommend spinal health content');
      } else if (mostFrequentActivityName.toLowerCase().contains('running') || mostFrequentActivityName.toLowerCase().contains('cardio') || mostFrequentActivityName.toLowerCase().contains('aerobic')) {
        specialGuidance = "Since the user frequently performs aerobic exercises, prioritize content related to cardiovascular function, endurance improvement, and exercise recovery.";
        debugPrint('Detected aerobic exercise pattern, will recommend cardiovascular content');
      } else if (mostFrequentActivityName.toLowerCase().contains('strength') || mostFrequentActivityName.toLowerCase().contains('weight') || mostFrequentActivityName.toLowerCase().contains('resistance')) {
        specialGuidance = "Since the user frequently performs strength training, prioritize content related to muscle growth, protein supplementation, and training plans.";
        debugPrint('Detected strength training pattern, will recommend muscle growth content');
      } else {
        debugPrint('No specific exercise pattern detected, using general recommendation strategy');
      }
        context += specialGuidance;
      } else {
        context += "User has no activity records, please provide general health and exercise beginner advice.";
      debugPrint('User has no activity records, will provide general health advice');
      }
      
      context += " Please ensure the advice is practical, specific, and motivational. Each suggestion should start with a number (1., 2., 3.), one per line.";
      debugPrint('Built prompt length: ${context.length} characters');
      debugPrint('Prompt content: $context');

      final apiKey = dotenv.env['OPENAI_API_KEY'];
      debugPrint('OpenAI API Key status: ${apiKey != null && apiKey.isNotEmpty ? "Configured" : "Not configured"}');
      
      debugPrint('Starting OpenAI API call...');
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
