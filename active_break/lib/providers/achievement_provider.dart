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

  /// Set UserProvider
  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  // Get achieved achievements
  List<UserAchievement> get achievedAchievements {
    return _userAchievements.where((ua) => ua.isAchieved).toList();
  }

  // Get unachieved achievements
  List<UserAchievement> get unachievedAchievements {
    return _userAchievements.where((ua) => !ua.isAchieved).toList();
  }

  // Get near completion achievements
  List<UserAchievement> get nearCompletionAchievements {
    return _userAchievements.where((ua) => ua.isNearCompletion).toList();
  }

  // Get achievement completion rate
  double get completionRate {
    if (_userAchievements.isEmpty) return 0.0;
    final achieved = achievedAchievements.length;
    return achieved / _userAchievements.length;
  }

  /// Initialize achievement data
  Future<void> initialize() async {
    await loadUserAchievements();
    await loadAllAchievements();
    await loadAchievementStats();
  }

  /// Load user achievements
  Future<void> loadUserAchievements([String? languageCode]) async {
    try {
      _setLoading(true);
      _setError(null);

      final currentUser = _userProvider?.currentUser;
      if (currentUser != null) {
        // If no language code provided, use default Chinese
        final langCode = languageCode ?? 'zh';
        _userAchievements = await _achievementService.getUserAchievements(
          currentUser.userId!,
          langCode,
        );

        // Sort achievements: completed ones first, then incomplete ones
        _userAchievements.sort((a, b) {
          // If one is completed and one is not, completed comes first
          if (a.isAchieved && !b.isAchieved) return -1;
          if (!a.isAchieved && b.isAchieved) return 1;

          // If both are completed, sort by completion time in descending order (latest first)
          if (a.isAchieved && b.isAchieved) {
            if (a.achievedAt != null && b.achievedAt != null) {
              return b.achievedAt!.compareTo(a.achievedAt!);
            }
          }

          // If both are incomplete, sort by progress in descending order (higher progress first)
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
      _setError('Failed to load user achievements: $e');
      debugPrint('Failed to load user achievements: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all achievements
  Future<void> loadAllAchievements() async {
    try {
      _allAchievements = await _achievementService.getAllAchievements();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load all achievements: $e');
    }
  }

  /// Load achievement statistics
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
      debugPrint('Failed to load achievement statistics: $e');
    }
  }

  /// Check and update achievements (called after user operations)
  Future<List<Achievement>> checkAndUpdateAchievements() async {
    try {
      final currentUser = _userProvider?.currentUser;
      if (currentUser == null) return [];

      // Check newly achieved achievements
      final newlyAchieved = await _achievementService
          .checkAndUpdateAchievements(currentUser.userId!);

      // Reload data
      await loadUserAchievements();
      await loadAchievementStats();

      return newlyAchieved;
    } catch (e) {
      debugPrint('Failed to check achievements: $e');
      return [];
    }
  }

  /// Check achievements after check-in
  Future<List<Achievement>> checkAchievementsAfterCheckin([
    BuildContext? context,
  ]) async {
    debugPrint('Checking check-in related achievements');
    final newAchievements = await checkAndUpdateAchievements();

    if (newAchievements.isNotEmpty && context != null) {
      AchievementNotification.show(context, newAchievements);
    }

    return newAchievements;
  }

  /// Check achievements after exercise
  Future<List<Achievement>> checkAchievementsAfterExercise([
    BuildContext? context,
  ]) async {
    debugPrint('Checking exercise related achievements');
    final newAchievements = await checkAndUpdateAchievements();

    if (newAchievements.isNotEmpty && context != null) {
      AchievementNotification.show(context, newAchievements);
    }

    return newAchievements;
  }

  /// Get achievements of specific type
  List<UserAchievement> getAchievementsByType(String type) {
    return _userAchievements
        .where((ua) => ua.achievement?.type == type)
        .toList();
  }

  /// Get detailed information of specific achievement
  UserAchievement? getAchievementById(int achievementId) {
    try {
      return _userAchievements.firstWhere(
        (ua) => ua.achievementId == achievementId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await initialize();
  }

  /// Reset user achievements (for testing)
  Future<void> resetAchievements() async {
    try {
      final currentUser = _userProvider?.currentUser;
      if (currentUser != null) {
        await _achievementService.resetUserAchievements(currentUser.userId!);
        await refresh();
      }
    } catch (e) {
      debugPrint('Failed to reset achievements: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _setError(null);
  }

  /// Show achievement notification
  void showAchievementNotification(Achievement achievement) {
    // This can integrate notification system or show popup
    debugPrint('🎉 Congratulations! New achievement unlocked: ${achievement.name}');
    debugPrint('Achievement description: ${achievement.description}');
  }

  /// Show multiple achievement notifications
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
