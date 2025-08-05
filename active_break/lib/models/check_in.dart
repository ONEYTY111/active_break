class CheckIn {
  final int? checkinId;
  final int userId;
  final DateTime checkinDate;
  final DateTime checkinTime;
  final DateTime? createdAt;
  final bool deleted;

  CheckIn({
    this.checkinId,
    required this.userId,
    required this.checkinDate,
    required this.checkinTime,
    this.createdAt,
    this.deleted = false,
  });

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      checkinId: map['checkin_id'],
      userId: map['user_id'],
      checkinDate: DateTime.parse(map['checkin_date']),
      checkinTime: DateTime.parse(map['checkin_time']),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      deleted: map['deleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'checkin_id': checkinId,
      'user_id': userId,
      'checkin_date': checkinDate.toIso8601String().split('T')[0],
      'checkin_time': checkinTime.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }
}

class UserCheckinStreak {
  final int userId;
  final int currentStreak;
  final int longestStreak;
  final int totalCheckin;
  final DateTime lastCheckinDate;
  final DateTime? updatedAt;
  final bool deleted;

  UserCheckinStreak({
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCheckin,
    required this.lastCheckinDate,
    this.updatedAt,
    this.deleted = false,
  });

  factory UserCheckinStreak.fromMap(Map<String, dynamic> map) {
    return UserCheckinStreak(
      userId: map['user_id'],
      currentStreak: map['current_streak'],
      longestStreak: map['longest_streak'],
      totalCheckin: map['total_checkin'],
      lastCheckinDate: DateTime.parse(map['last_checkin_date']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      deleted: map['deleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_checkin': totalCheckin,
      'last_checkin_date': lastCheckinDate.toIso8601String().split('T')[0],
      'updated_at': updatedAt?.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }
}
