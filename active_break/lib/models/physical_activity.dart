class PhysicalActivity {
  final int? activityTypeId;
  final String name;
  final String description;
  final int caloriesPerMinute;
  final int defaultDuration;
  final String iconUrl;
  final bool deleted;

  PhysicalActivity({
    this.activityTypeId,
    required this.name,
    required this.description,
    required this.caloriesPerMinute,
    required this.defaultDuration,
    required this.iconUrl,
    this.deleted = false,
  });

  factory PhysicalActivity.fromMap(Map<String, dynamic> map) {
    return PhysicalActivity(
      activityTypeId: map['activity_type_id'],
      name: map['name'],
      description: map['description'],
      caloriesPerMinute: map['calories_per_minute'],
      defaultDuration: map['default_duration'],
      iconUrl: map['icon_url'],
      deleted: map['deleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activity_type_id': activityTypeId,
      'name': name,
      'description': description,
      'calories_per_minute': caloriesPerMinute,
      'default_duration': defaultDuration,
      'icon_url': iconUrl,
      'deleted': deleted ? 1 : 0,
    };
  }
}

class ActivityRecord {
  final int? recordId;
  final int userId;
  final int activityTypeId;
  final int durationMinutes;
  final int caloriesBurned;
  final DateTime beginTime;
  final DateTime endTime;
  final bool deleted;

  ActivityRecord({
    this.recordId,
    required this.userId,
    required this.activityTypeId,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.beginTime,
    required this.endTime,
    this.deleted = false,
  });

  factory ActivityRecord.fromMap(Map<String, dynamic> map) {
    return ActivityRecord(
      recordId: map['record_id'],
      userId: map['user_id'],
      activityTypeId: map['activity_type_id'],
      durationMinutes: map['duration_minutes'],
      caloriesBurned: map['calories_burned'],
      beginTime: DateTime.parse(map['begin_time']),
      endTime: DateTime.parse(map['end_time']),
      deleted: map['deleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'record_id': recordId,
      'user_id': userId,
      'activity_type_id': activityTypeId,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'begin_time': beginTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }
}
