import 'achievement.dart';

class UserAchievement {
  final int? userAchievementId;
  final int userId;
  final int achievementId;
  final DateTime? achievedAt;
  final int currentProgress;
  final bool isAchieved;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  
  // Associated achievement information
  final Achievement? achievement;

  UserAchievement({
    this.userAchievementId,
    required this.userId,
    required this.achievementId,
    this.achievedAt,
    this.currentProgress = 0,
    this.isAchieved = false,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
    this.achievement,
  });

  factory UserAchievement.fromMap(Map<String, dynamic> map) {
    Achievement? achievement;
    
    // If achievement information is included, create Achievement object
    if (map.containsKey('name') && map['name'] != null) {
      achievement = Achievement.fromMap(map);
    }
    
    return UserAchievement(
      userAchievementId: map['user_achievement_id'],
      userId: map['user_id'] ?? 0,
      achievementId: map['achievement_id'] ?? 0,
      achievedAt: map['achieved_at'] != null 
          ? DateTime.parse(map['achieved_at']) 
          : null,
      currentProgress: map['current_progress'] ?? 0,
      isAchieved: (map['is_achieved'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
      deleted: (map['deleted'] ?? 0) == 1,
      achievement: achievement,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (userAchievementId != null) 'user_achievement_id': userAchievementId,
      'user_id': userId,
      'achievement_id': achievementId,
      if (achievedAt != null) 'achieved_at': achievedAt!.toIso8601String(),
      'current_progress': currentProgress,
      'is_achieved': isAchieved ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }

  // Calculate progress percentage
  double get progressPercentage {
    if (achievement == null || achievement!.targetValue == 0) return 0.0;
    return (currentProgress / achievement!.targetValue).clamp(0.0, 1.0);
  }

  // Whether close to completion (progress over 80%)
  bool get isNearCompletion {
    return progressPercentage >= 0.8 && !isAchieved;
  }

  UserAchievement copyWith({
    int? userAchievementId,
    int? userId,
    int? achievementId,
    DateTime? achievedAt,
    int? currentProgress,
    bool? isAchieved,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
    Achievement? achievement,
  }) {
    return UserAchievement(
      userAchievementId: userAchievementId ?? this.userAchievementId,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      achievedAt: achievedAt ?? this.achievedAt,
      currentProgress: currentProgress ?? this.currentProgress,
      isAchieved: isAchieved ?? this.isAchieved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      achievement: achievement ?? this.achievement,
    );
  }

  @override
  String toString() {
    return 'UserAchievement{userAchievementId: $userAchievementId, userId: $userId, achievementId: $achievementId, achievedAt: $achievedAt, currentProgress: $currentProgress, isAchieved: $isAchieved, createdAt: $createdAt, updatedAt: $updatedAt, deleted: $deleted, achievement: $achievement}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAchievement && 
           other.userId == userId && 
           other.achievementId == achievementId;
  }

  @override
  int get hashCode => Object.hash(userId, achievementId);
}