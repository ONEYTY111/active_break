import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/reminder_and_tips.dart';
import '../services/database_service.dart';

class TipsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Dio _dio = Dio();
  
  List<UserTip> _todayTips = [];
  bool _isLoading = false;
  
  List<UserTip> get todayTips => _todayTips;
  bool get isLoading => _isLoading;

  Future<void> loadTodayTips(int userId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _todayTips = await _databaseService.getTodayUserTips(userId);
      
      // If no tips for today, generate some
      if (_todayTips.isEmpty) {
        await _generateDailyTips(userId);
        _todayTips = await _databaseService.getTodayUserTips(userId);
      }
    } catch (e) {
      debugPrint('Error loading today tips: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _generateDailyTips(int userId) async {
    try {
      List<String> tips;
      
      // For now, use mock tips. Users can configure OpenAI API later
      // To enable OpenAI, uncomment the line below and add your API key
      // tips = await _generateTipsWithOpenAI(userId, 'your_openai_api_key_here');
      tips = await _generateMockTips();
      
      final today = DateTime.now();
      for (final tipContent in tips) {
        final tip = UserTip(
          userId: userId,
          tipDate: today,
          content: tipContent,
        );
        await _databaseService.insertUserTip(tip);
      }
    } catch (e) {
      debugPrint('Error generating daily tips: $e');
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
    try {
      // Get user's activity history for personalization
      final recentActivities = await _databaseService.getRecentActivityRecords(userId);
      
      // Build context for OpenAI
      String context = "Generate exactly 3 personalized health and fitness tips for a user who has been doing: ";
      if (recentActivities.isNotEmpty) {
        final activities = recentActivities.map((r) => "activity for ${r.durationMinutes} minutes").join(", ");
        context += activities;
      } else {
        context += "no recent activities";
      }
      context += ". Make the tips practical, motivating, and specific. Return each tip as a separate line starting with a number (1., 2., 3.).";

      final apiKey = dotenv.env['OPENAI_API_KEY'];
      
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
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

      final content = response.data['choices'][0]['message']['content'] as String;
      
      // Parse the response to extract individual tips
      final tips = content.split('\n')
          .where((line) => line.trim().isNotEmpty && line.contains('.'))
          .map((line) => line.replaceAll(RegExp(r'^\d+\.\s*'), '').trim())
          .take(3)
          .toList();

      // Ensure we have exactly 3 tips
      if (tips.length < 3) {
        debugPrint('OpenAI returned less than 3 tips, falling back to mock tips');
        return await _generateMockTips();
      }

      return tips;
    } catch (e) {
      debugPrint('Error generating tips with OpenAI: $e');
      return await _generateMockTips();
    }
  }
}
