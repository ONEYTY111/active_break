import 'package:flutter/foundation.dart';
import '../models/achievement.dart';
import '../models/user_achievement.dart';
import '../models/check_in.dart';
import '../models/physical_activity.dart';
import 'database_service.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Get all achievements
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final maps = await _databaseService.getAllAchievements();
      return maps.map((map) => Achievement.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Failed to get all achievements: $e');
      return [];
    }
  }

  /// Get user achievement list (including progress information)
  Future<List<UserAchievement>> getUserAchievements(
    int userId, [
    String languageCode = 'zh',
  ]) async {
    try {
      final maps = await _databaseService.getUserAchievements(
        userId,
        languageCode,
      );
      return maps.map((map) => UserAchievement.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Failed to get user achievements: $e');
      return [];
    }
  }

  /// Get user's achieved achievements
  Future<List<UserAchievement>> getUserAchievedAchievements(int userId) async {
    final allAchievements = await getUserAchievements(userId);
    return allAchievements.where((ua) => ua.isAchieved).toList();
  }

  /// Get user's unachieved achievements
  Future<List<UserAchievement>> getUserUnachievedAchievements(
    int userId,
  ) async {
    final allAchievements = await getUserAchievements(userId);
    return allAchievements.where((ua) => !ua.isAchieved).toList();
  }

  /// Check and update user achievements
  Future<List<Achievement>> checkAndUpdateAchievements(int userId) async {
    final newlyAchieved = <Achievement>[];

    try {
      // Get all achievements
      final achievements = await getAllAchievements();

      for (final achievement in achievements) {
        // First get current achievement status (before update)
        final existingAchievement = await _getUserAchievement(
          userId,
          achievement.achievementId,
        );
        final wasAchieved = existingAchievement?.isAchieved ?? false;

        final progress = await _calculateProgress(userId, achievement);
        final isAchieved = progress >= achievement.targetValue;

        debugPrint(
          'Achievement check: ${achievement.name}, progress: $progress/${achievement.targetValue}, achieved: $isAchieved, previously achieved: $wasAchieved',
        );

        // Update user achievement record
        await _databaseService.updateUserAchievement(
          userId,
          achievement.achievementId,
          progress,
          isAchieved,
        );

        // If it's a newly achieved achievement, add to list
        if (isAchieved && !wasAchieved) {
          debugPrint('New achievement unlocked: ${achievement.name}');
          newlyAchieved.add(achievement);
        }
      }
    } catch (e) {
      debugPrint('Failed to check user achievements: $e');
    }

    return newlyAchieved;
  }

  /// Calculate progress for specific achievement
  Future<int> _calculateProgress(int userId, Achievement achievement) async {
    try {
      switch (achievement.type) {
        case 'checkin_count':
          return await _getCheckinCount(userId);
        case 'checkin_streak':
          return await _getCheckinStreak(userId);
        case 'exercise_count':
          return await _getExerciseCount(userId);
        case 'exercise_streak':
          return await _getExerciseStreak(userId);
        case 'calories_burned':
          return await _getTotalCaloriesBurned(userId);
        case 'exercise_duration':
          return await _getTotalExerciseDuration(userId);
        default:
          return 0;
      }
    } catch (e) {
      debugPrint('Failed to calculate achievement progress: $e');
      return 0;
    }
  }

  /// Get user's total check-in count
  Future<int> _getCheckinCount(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM t_check_in WHERE user_id = ? AND deleted = 0',
      [userId],
    );
    return result.first['count'] as int;
  }

  /// Get user's current consecutive check-in days
  Future<int> _getCheckinStreak(int userId) async {
    final db = await _databaseService.database;
    final result = await db.query(
      't_user_checkin_streaks',
      where: 'user_id = ? AND deleted = 0',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first['current_streak'] as int;
    }
    return 0;
  }

  /// Get user's total exercise count
  Future<int> _getExerciseCount(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM t_activi_record WHERE user_id = ? AND deleted = 0',
      [userId],
    );
    return result.first['count'] as int;
  }

  /// Get user's consecutive exercise days
  Future<int> _getExerciseStreak(int userId) async {
    final db = await _databaseService.database;

    // Get all user exercise records, grouped by date
    final result = await db.rawQuery(
      '''
      SELECT DATE(begin_time) as exercise_date
      FROM t_activi_record 
      WHERE user_id = ? AND deleted = 0
      GROUP BY DATE(begin_time)
      ORDER BY exercise_date DESC
    ''',
      [userId],
    );

    if (result.isEmpty) return 0;

    // Calculate consecutive exercise days
    int streak = 0;
    DateTime? lastDate;

    for (final row in result) {
      final dateStr = row['exercise_date'] as String;
      final date = DateTime.parse(dateStr);

      if (lastDate == null) {
        // First record
        lastDate = date;
        streak = 1;
      } else {
        // Check if consecutive
        final difference = lastDate.difference(date).inDays;
        if (difference == 1) {
          streak++;
          lastDate = date;
        } else {
          break; // Not consecutive, stop calculation
        }
      }
    }

    return streak;
  }

  /// Get user's total calories burned
  Future<int> _getTotalCaloriesBurned(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT SUM(calories_burned) as total FROM t_activi_record WHERE user_id = ? AND deleted = 0',
      [userId],
    );

    final total = result.first['total'];
    return total != null ? (total as num).toInt() : 0;
  }

  /// Get user's total exercise duration (minutes)
  Future<int> _getTotalExerciseDuration(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT SUM(duration_minutes) as total FROM t_activi_record WHERE user_id = ? AND deleted = 0',
      [userId],
    );

    final total = result.first['total'];
    return total != null ? (total as num).toInt() : 0;
  }

  /// Get specific user achievement record
  Future<UserAchievement?> _getUserAchievement(
    int userId,
    int achievementId,
  ) async {
    try {
      final db = await _databaseService.database;
      final result = await db.query(
        'user_achievements',
        where: 'user_id = ? AND achievement_id = ? AND deleted = 0',
        whereArgs: [userId, achievementId],
      );

      if (result.isNotEmpty) {
        return UserAchievement.fromMap(result.first);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get user achievement record: $e');
      return null;
    }
  }

  /// Get user achievement statistics
  Future<Map<String, int>> getUserAchievementStats(int userId) async {
    try {
      final userAchievements = await getUserAchievements(userId);
      final achieved = userAchievements.where((ua) => ua.isAchieved).length;
      final total = userAchievements.length;
      final nearCompletion = userAchievements
          .where((ua) => ua.isNearCompletion)
          .length;

      return {
        'total': total,
        'achieved': achieved,
        'unachieved': total - achieved,
        'nearCompletion': nearCompletion,
      };
    } catch (e) {
      debugPrint('Failed to get user achievement statistics: $e');
      return {'total': 0, 'achieved': 0, 'unachieved': 0, 'nearCompletion': 0};
    }
  }

  /// Reset all user achievement progress (for testing)
  Future<void> resetUserAchievements(int userId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'user_achievements',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      debugPrint('User achievement progress has been reset');
    } catch (e) {
      debugPrint('Failed to reset user achievements: $e');
    }
  }

  /// Get user check-in count (for debugging)
  Future<int> getCheckinCount(int userId) async {
    return await _getCheckinCount(userId);
  }

  /// Get user exercise count (for debugging)
  Future<int> getExerciseCount(int userId) async {
    return await _getExerciseCount(userId);
  }
}
