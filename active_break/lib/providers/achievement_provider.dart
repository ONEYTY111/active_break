import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/user_achievement.dart';
import '../services/achievement_service.dart';
import '../widgets/achievement_notification.dart';
import 'user_provider.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _achievementService = AchievementService();
  UserProvider? _userProvider;

  List<UserAchievement> _userAchievements = [];
  List<Achievement> _allAchievements = [];
  Map<String, int> _achievementStats = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserAchievement> get userAchievements => _userAchievements;
  List<Achievement> get allAchievements => _allAchievements;
  Map<String, int> get achievementStats => _achievementStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 设置UserProvider
  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  // 获取已达成的成就
  List<UserAchievement> get achievedAchievements {
    return _userAchievements.where((ua) => ua.isAchieved).toList();
  }

  // 获取未达成的成就
  List<UserAchievement> get unachievedAchievements {
    return _userAchievements.where((ua) => !ua.isAchieved).toList();
  }

  // 获取接近完成的成就
  List<UserAchievement> get nearCompletionAchievements {
    return _userAchievements.where((ua) => ua.isNearCompletion).toList();
  }

  // 获取成就完成率
  double get completionRate {
    if (_userAchievements.isEmpty) return 0.0;
    final achieved = achievedAchievements.length;
    return achieved / _userAchievements.length;
  }

  /// 初始化成就数据
  Future<void> initialize() async {
    await loadUserAchievements();
    await loadAllAchievements();
    await loadAchievementStats();
  }

  /// 加载用户成就
  Future<void> loadUserAchievements([String? languageCode]) async {
    try {
      _setLoading(true);
      _setError(null);

      final currentUser = _userProvider?.currentUser;
      if (currentUser != null) {
        // 如果没有提供语言代码，使用默认的中文
        final langCode = languageCode ?? 'zh';
        _userAchievements = await _achievementService.getUserAchievements(
          currentUser.userId!,
          langCode,
        );

        // 对成就进行排序：已完成的在前面，未完成的在后面
        _userAchievements.sort((a, b) {
          // 如果一个已完成，一个未完成，已完成的排在前面
          if (a.isAchieved && !b.isAchieved) return -1;
          if (!a.isAchieved && b.isAchieved) return 1;

          // 如果都已完成，按完成时间倒序排列（最新完成的在前面）
          if (a.isAchieved && b.isAchieved) {
            if (a.achievedAt != null && b.achievedAt != null) {
              return b.achievedAt!.compareTo(a.achievedAt!);
            }
          }

          // 如果都未完成，按进度倒序排列（进度高的在前面）
          if (!a.isAchieved && !b.isAchieved) {
            return b.currentProgress.compareTo(a.currentProgress);
          }

          return 0;
        });
      } else {
        _userAchievements = [];
      }

      notifyListeners();
    } catch (e) {
      _setError('加载用户成就失败: $e');
      debugPrint('加载用户成就失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载所有成就
  Future<void> loadAllAchievements() async {
    try {
      _allAchievements = await _achievementService.getAllAchievements();
      notifyListeners();
    } catch (e) {
      debugPrint('加载所有成就失败: $e');
    }
  }

  /// 加载成就统计信息
  Future<void> loadAchievementStats() async {
    try {
      final currentUser = _userProvider?.currentUser;
      if (currentUser != null) {
        _achievementStats = await _achievementService.getUserAchievementStats(
          currentUser.userId!,
        );
      } else {
        _achievementStats = {};
      }
      notifyListeners();
    } catch (e) {
      debugPrint('加载成就统计失败: $e');
    }
  }

  /// 检查并更新成就（在用户操作后调用）
  Future<List<Achievement>> checkAndUpdateAchievements() async {
    try {
      final currentUser = _userProvider?.currentUser;
      if (currentUser == null) return [];

      // 检查新达成的成就
      final newlyAchieved = await _achievementService
          .checkAndUpdateAchievements(currentUser.userId!);

      // 重新加载数据
      await loadUserAchievements();
      await loadAchievementStats();

      return newlyAchieved;
    } catch (e) {
      debugPrint('检查成就失败: $e');
      return [];
    }
  }

  /// 在打卡后检查成就
  Future<List<Achievement>> checkAchievementsAfterCheckin([
    BuildContext? context,
  ]) async {
    debugPrint('检查打卡相关成就');
    final newAchievements = await checkAndUpdateAchievements();

    if (newAchievements.isNotEmpty && context != null) {
      AchievementNotification.show(context, newAchievements);
    }

    return newAchievements;
  }

  /// 在运动后检查成就
  Future<List<Achievement>> checkAchievementsAfterExercise([
    BuildContext? context,
  ]) async {
    debugPrint('检查运动相关成就');
    final newAchievements = await checkAndUpdateAchievements();

    if (newAchievements.isNotEmpty && context != null) {
      AchievementNotification.show(context, newAchievements);
    }

    return newAchievements;
  }

  /// 获取特定类型的成就
  List<UserAchievement> getAchievementsByType(String type) {
    return _userAchievements
        .where((ua) => ua.achievement?.type == type)
        .toList();
  }

  /// 获取特定成就的详细信息
  UserAchievement? getAchievementById(int achievementId) {
    try {
      return _userAchievements.firstWhere(
        (ua) => ua.achievementId == achievementId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 刷新所有数据
  Future<void> refresh() async {
    await initialize();
  }

  /// 重置用户成就（用于测试）
  Future<void> resetAchievements() async {
    try {
      final currentUser = _userProvider?.currentUser;
      if (currentUser != null) {
        await _achievementService.resetUserAchievements(currentUser.userId!);
        await refresh();
      }
    } catch (e) {
      debugPrint('重置成就失败: $e');
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _setError(null);
  }

  /// 显示成就达成通知
  void showAchievementNotification(Achievement achievement) {
    // 这里可以集成通知系统或显示弹窗
    debugPrint('🎉 恭喜！您获得了新成就: ${achievement.name}');
    debugPrint('成就描述: ${achievement.description}');
  }

  /// 批量显示成就达成通知
  void showMultipleAchievementNotifications(List<Achievement> achievements) {
    for (final achievement in achievements) {
      showAchievementNotification(achievement);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
