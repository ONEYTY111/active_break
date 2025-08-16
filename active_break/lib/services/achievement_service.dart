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

  /// 获取所有成就
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final maps = await _databaseService.getAllAchievements();
      return maps.map((map) => Achievement.fromMap(map)).toList();
    } catch (e) {
      debugPrint('获取所有成就失败: $e');
      return [];
    }
  }

  /// 获取用户成就列表（包含进度信息）
  Future<List<UserAchievement>> getUserAchievements(int userId) async {
    try {
      final maps = await _databaseService.getUserAchievements(userId);
      return maps.map((map) => UserAchievement.fromMap(map)).toList();
    } catch (e) {
      debugPrint('获取用户成就失败: $e');
      return [];
    }
  }

  /// 获取用户已达成的成就
  Future<List<UserAchievement>> getUserAchievedAchievements(int userId) async {
    final allAchievements = await getUserAchievements(userId);
    return allAchievements.where((ua) => ua.isAchieved).toList();
  }

  /// 获取用户未达成的成就
  Future<List<UserAchievement>> getUserUnachievedAchievements(int userId) async {
    final allAchievements = await getUserAchievements(userId);
    return allAchievements.where((ua) => !ua.isAchieved).toList();
  }

  /// 检查并更新用户成就
  Future<List<Achievement>> checkAndUpdateAchievements(int userId) async {
    final newlyAchieved = <Achievement>[];
    
    try {
      // 获取所有成就
      final achievements = await getAllAchievements();
      
      for (final achievement in achievements) {
        // 先获取当前成就状态（更新前）
        final existingAchievement = await _getUserAchievement(userId, achievement.achievementId);
        final wasAchieved = existingAchievement?.isAchieved ?? false;
        
        final progress = await _calculateProgress(userId, achievement);
        final isAchieved = progress >= achievement.targetValue;
        
        debugPrint('成就检查: ${achievement.name}, 进度: $progress/${achievement.targetValue}, 是否达成: $isAchieved, 之前是否达成: $wasAchieved');
        
        // 更新用户成就记录
        await _databaseService.updateUserAchievement(
          userId, 
          achievement.achievementId, 
          progress, 
          isAchieved
        );
        
        // 如果是新达成的成就，添加到列表
        if (isAchieved && !wasAchieved) {
          debugPrint('新达成成就: ${achievement.name}');
          newlyAchieved.add(achievement);
        }
      }
    } catch (e) {
      debugPrint('检查用户成就失败: $e');
    }
    
    return newlyAchieved;
  }

  /// 计算特定成就的进度
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
      debugPrint('计算成就进度失败: $e');
      return 0;
    }
  }

  /// 获取用户打卡总数
  Future<int> _getCheckinCount(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM t_check_in WHERE user_id = ? AND deleted = 0',
      [userId]
    );
    return result.first['count'] as int;
  }

  /// 获取用户当前打卡连续天数
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

  /// 获取用户运动总次数
  Future<int> _getExerciseCount(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM t_activi_record WHERE user_id = ? AND deleted = 0',
      [userId]
    );
    return result.first['count'] as int;
  }

  /// 获取用户连续运动天数
  Future<int> _getExerciseStreak(int userId) async {
    final db = await _databaseService.database;
    
    // 获取用户所有运动记录，按日期分组
    final result = await db.rawQuery('''
      SELECT DATE(begin_time) as exercise_date
      FROM t_activi_record 
      WHERE user_id = ? AND deleted = 0
      GROUP BY DATE(begin_time)
      ORDER BY exercise_date DESC
    ''', [userId]);
    
    if (result.isEmpty) return 0;
    
    // 计算连续运动天数
    int streak = 0;
    DateTime? lastDate;
    
    for (final row in result) {
      final dateStr = row['exercise_date'] as String;
      final date = DateTime.parse(dateStr);
      
      if (lastDate == null) {
        // 第一条记录
        lastDate = date;
        streak = 1;
      } else {
        // 检查是否连续
        final difference = lastDate.difference(date).inDays;
        if (difference == 1) {
          streak++;
          lastDate = date;
        } else {
          break; // 不连续，停止计算
        }
      }
    }
    
    return streak;
  }

  /// 获取用户总消耗卡路里
  Future<int> _getTotalCaloriesBurned(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT SUM(calories_burned) as total FROM t_activi_record WHERE user_id = ? AND deleted = 0',
      [userId]
    );
    
    final total = result.first['total'];
    return total != null ? (total as num).toInt() : 0;
  }

  /// 获取用户总运动时长（分钟）
  Future<int> _getTotalExerciseDuration(int userId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT SUM(duration_minutes) as total FROM t_activi_record WHERE user_id = ? AND deleted = 0',
      [userId]
    );
    
    final total = result.first['total'];
    return total != null ? (total as num).toInt() : 0;
  }

  /// 获取特定用户成就记录
  Future<UserAchievement?> _getUserAchievement(int userId, int achievementId) async {
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
      debugPrint('获取用户成就记录失败: $e');
      return null;
    }
  }

  /// 获取用户成就统计信息
  Future<Map<String, int>> getUserAchievementStats(int userId) async {
    try {
      final userAchievements = await getUserAchievements(userId);
      final achieved = userAchievements.where((ua) => ua.isAchieved).length;
      final total = userAchievements.length;
      final nearCompletion = userAchievements.where((ua) => ua.isNearCompletion).length;
      
      return {
        'total': total,
        'achieved': achieved,
        'unachieved': total - achieved,
        'nearCompletion': nearCompletion,
      };
    } catch (e) {
      debugPrint('获取用户成就统计失败: $e');
      return {
        'total': 0,
        'achieved': 0,
        'unachieved': 0,
        'nearCompletion': 0,
      };
    }
  }

  /// 重置用户所有成就进度（用于测试）
  Future<void> resetUserAchievements(int userId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'user_achievements',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      debugPrint('用户成就进度已重置');
    } catch (e) {
      debugPrint('重置用户成就失败: $e');
    }
  }

  /// 获取用户打卡次数（调试用）
  Future<int> getCheckinCount(int userId) async {
    return await _getCheckinCount(userId);
  }

  /// 获取用户运动次数（调试用）
  Future<int> getExerciseCount(int userId) async {
    return await _getExerciseCount(userId);
  }
}