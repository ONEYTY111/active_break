import 'package:flutter/material.dart';
import '../models/physical_activity.dart';
import '../models/check_in.dart';
import '../models/reminder_and_tips.dart';
import '../services/database_service.dart';

class ActivityProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<PhysicalActivity> _activities = [];
  List<ActivityRecord> _recentRecords = [];
  UserCheckinStreak? _checkinStreak;
  bool _isLoading = false;

  // Timer related
  bool _isTimerRunning = false;
  int _currentActivityId = 0;
  DateTime? _timerStartTime;
  Duration _elapsedTime = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Duration _remainingTime = Duration.zero;
  bool _needsAutoComplete = false;
  bool _isSaving = false; // Prevent duplicate saves

  List<PhysicalActivity> get activities => _activities;
  List<ActivityRecord> get recentRecords => _recentRecords;
  UserCheckinStreak? get checkinStreak => _checkinStreak;
  bool get isLoading => _isLoading;
  bool get isTimerRunning => _isTimerRunning;
  int get currentActivityId => _currentActivityId;
  Duration get elapsedTime => _elapsedTime;
  Duration get remainingTime => _remainingTime;
  Duration get totalDuration => _totalDuration;
  bool get isCountdownFinished =>
      _remainingTime == Duration.zero && _totalDuration > Duration.zero;
  bool get needsAutoComplete => _needsAutoComplete;

  Future<void> loadActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await _databaseService.getAllPhysicalActivities();
    } catch (e) {
      debugPrint('Error loading activities: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setActivities(List<PhysicalActivity> activities) {
    _activities = activities;
    notifyListeners();
  }

  Future<void> reloadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activities = await _databaseService.getAllPhysicalActivities();
    } catch (e) {
      debugPrint('Error reloading activities: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecentRecords(int userId) async {
    try {
      _recentRecords = await _databaseService.getRecentActivityRecords(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent records: $e');
    }
  }

  Future<void> loadCheckinStreak(int userId) async {
    try {
      _checkinStreak = await _databaseService.getUserCheckinStreak(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading checkin streak: $e');
    }
  }

  Future<bool> checkInToday(int userId) async {
    try {
      // Check if already checked in today
      final todayCheckIn = await _databaseService.getTodayCheckIn(userId);
      if (todayCheckIn != null) {
        return false; // Already checked in
      }

      final now = DateTime.now();
      final checkIn = CheckIn(
        userId: userId,
        checkinDate: now,
        checkinTime: now,
        createdAt: now,
      );

      await _databaseService.insertCheckIn(checkIn);

      // Update streak
      await _updateCheckinStreak(userId);

      return true;
    } catch (e) {
      debugPrint('Error checking in: $e');
      return false;
    }
  }

  Future<void> _updateCheckinStreak(int userId) async {
    try {
      final existing = await _databaseService.getUserCheckinStreak(userId);
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      if (existing == null) {
        // First check-in
        final newStreak = UserCheckinStreak(
          userId: userId,
          currentStreak: 1,
          longestStreak: 1,
          totalCheckin: 1,
          lastCheckinDate: today,
          updatedAt: today,
        );
        await _databaseService.insertOrUpdateCheckinStreak(newStreak);
        _checkinStreak = newStreak;
      } else {
        final lastCheckinDate = existing.lastCheckinDate;
        int newCurrentStreak;

        if (lastCheckinDate.year == yesterday.year &&
            lastCheckinDate.month == yesterday.month &&
            lastCheckinDate.day == yesterday.day) {
          // Consecutive day
          newCurrentStreak = existing.currentStreak + 1;
        } else {
          // Not consecutive
          newCurrentStreak = 1;
        }

        final newLongestStreak = newCurrentStreak > existing.longestStreak
            ? newCurrentStreak
            : existing.longestStreak;

        final updatedStreak = UserCheckinStreak(
          userId: userId,
          currentStreak: newCurrentStreak,
          longestStreak: newLongestStreak,
          totalCheckin: existing.totalCheckin + 1,
          lastCheckinDate: today,
          updatedAt: today,
        );

        await _databaseService.insertOrUpdateCheckinStreak(updatedStreak);
        _checkinStreak = updatedStreak;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating checkin streak: $e');
    }
  }

  void startTimer(int activityId) {
    _isTimerRunning = true;
    _currentActivityId = activityId;
    _timerStartTime = DateTime.now();
    _elapsedTime = Duration.zero;

    // Get activity default duration (convert minutes to seconds)
    final activity = _activities.firstWhere(
      (a) => a.activityTypeId == activityId,
      orElse: () => throw Exception('Activity not found'),
    );
    _totalDuration = Duration(minutes: activity.defaultDuration);
    _remainingTime = _totalDuration;

    notifyListeners();
  }

  void stopTimer() {
    _isTimerRunning = false;
    _currentActivityId = 0;
    _timerStartTime = null;
    _elapsedTime = Duration.zero;
    _totalDuration = Duration.zero;
    _remainingTime = Duration.zero;
    _needsAutoComplete = false;
    notifyListeners();
  }

  void updateTimer() {
    if (_isTimerRunning && _timerStartTime != null) {
      _elapsedTime = DateTime.now().difference(_timerStartTime!);
      _remainingTime = _totalDuration - _elapsedTime;

      // If countdown ends, automatically complete exercise
      if (_remainingTime.isNegative || _remainingTime == Duration.zero) {
        _remainingTime = Duration.zero;
        _elapsedTime = _totalDuration;
        // Mark as needing auto-save
        _autoCompleteTimer();
      }

      notifyListeners();
    }
  }

  void _autoCompleteTimer() {
    // Mark as needing auto-completion, ExerciseScreen will listen to this state
    _needsAutoComplete = true;
    _isTimerRunning = false;
    notifyListeners();
  }

  void clearAutoCompleteFlag() {
    _needsAutoComplete = false;
    notifyListeners();
  }

  Future<bool> saveActivityRecord(int userId) async {
    // Allow saving record during auto-completion, even if timer is stopped
    if (_timerStartTime == null ||
        (_currentActivityId == 0 && !_needsAutoComplete))
      return false;

    // Prevent duplicate saves
    if (_isSaving) return false;
    _isSaving = true;

    try {
      final activity = _activities.firstWhere(
        (a) => a.activityTypeId == _currentActivityId,
      );

      final endTime = DateTime.now();
      final durationMinutes = _elapsedTime.inMinutes;
      final caloriesBurned = (durationMinutes * activity.caloriesPerMinute)
          .round();

      // Debug print for calorie calculation
      debugPrint(
        'Calorie calculation: duration=${durationMinutes}min, calories per minute=${activity.caloriesPerMinute}, total calories=${caloriesBurned}',
      );

      final record = ActivityRecord(
        userId: userId,
        activityTypeId: _currentActivityId,
        durationMinutes: durationMinutes,
        caloriesBurned: caloriesBurned,
        beginTime: _timerStartTime!,
        endTime: endTime,
      );

      await _databaseService.insertActivityRecord(record);

      // Debug print for recent records
      debugPrint('Recent records count after saving activity record: ${_recentRecords.length}');
      for (var record in _recentRecords) {
        debugPrint(
          '  Record: activityID=${record.activityTypeId}, startTime=${record.beginTime}, endTime=${record.endTime}',
        );
      }

      // Reload recent records
      await loadRecentRecords(userId);

      // Stop timer
      stopTimer();

      // Clear auto-complete flag
      _needsAutoComplete = false;

      // Notify listeners with updated weekly data
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error saving activity record: $e');
      return false;
    } finally {
      _isSaving = false;
    }
  }

  Future<void> updateReminderSetting(
    int userId,
    int activityTypeId,
    ReminderSetting setting,
  ) async {
    try {
      await _databaseService.insertOrUpdateReminderSetting(setting);
    } catch (e) {
      debugPrint('Error updating reminder setting: $e');
    }
  }

  Future<ReminderSetting?> getReminderSetting(
    int userId,
    int activityTypeId,
  ) async {
    try {
      return await _databaseService.getReminderSetting(userId, activityTypeId);
    } catch (e) {
      debugPrint('Error getting reminder setting: $e');
      return null;
    }
  }

  Future<List<ActivityRecord>> getWeeklyRecords(int userId) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      return await _databaseService.getActivityRecordsByDateRange(
        userId,
        startOfWeek,
        endOfWeek,
      );
    } catch (e) {
      debugPrint('Error getting weekly records: $e');
      return [];
    }
  }
}
