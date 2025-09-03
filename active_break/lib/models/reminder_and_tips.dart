class ReminderSetting {
  final int? reminderId;
  final int userId;
  final int activityTypeId;
  final bool enabled;
  final int intervalValue;
  final int intervalWeek;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool deleted;

  ReminderSetting({
    this.reminderId,
    required this.userId,
    required this.activityTypeId,
    required this.enabled,
    required this.intervalValue,
    required this.intervalWeek,
    required this.startTime,
    required this.endTime,
    this.createdAt,
    this.updatedAt,
    this.deleted = false,
  });

  factory ReminderSetting.fromMap(Map<String, dynamic> map) {
    return ReminderSetting(
      reminderId: map['reminder_id'],
      userId: map['user_id'],
      activityTypeId: map['activity_type_id'],
      enabled: map['enabled'] == 1,
      intervalValue: map['interval_value'],
      intervalWeek: map['interval_week'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      deleted: map['deleted'] == 1,
    );
  }

  /**
   * 转换为数据库映射（用于插入操作）
   * @author Author
   * @date Current date and time
   * @return Map<String, dynamic> 包含所有字段的数据库映射
   */
  Map<String, dynamic> toMapForInsert() {
    return {
      'reminder_id': reminderId,
      'user_id': userId,
      'activity_type_id': activityTypeId,
      'enabled': enabled ? 1 : 0,
      'interval_value': intervalValue,
      'interval_week': intervalWeek,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }

  /**
   * 转换为数据库映射（用于更新操作）
   * @author Author
   * @date Current date and time
   * @return Map<String, dynamic> 不包含主键的数据库映射
   */
  Map<String, dynamic> toMapForUpdate() {
    return {
      'user_id': userId,
      'activity_type_id': activityTypeId,
      'enabled': enabled ? 1 : 0,
      'interval_value': intervalValue,
      'interval_week': intervalWeek,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }

  /**
   * 转换为数据库映射（兼容旧版本）
   * @author Author
   * @date Current date and time
   * @return Map<String, dynamic> 数据库映射
   * @deprecated 请使用 toMapForInsert() 或 toMapForUpdate()
   */
  Map<String, dynamic> toMap() {
    return toMapForInsert();
  }
}

class UserTip {
  final int? tipId;
  final int userId;
  final DateTime tipDate;
  final String content;
  final bool deleted;

  UserTip({
    this.tipId,
    required this.userId,
    required this.tipDate,
    required this.content,
    this.deleted = false,
  });

  factory UserTip.fromMap(Map<String, dynamic> map) {
    return UserTip(
      tipId: map['tip_id'],
      userId: map['user_id'],
      tipDate: DateTime.parse(map['tip_date']),
      content: map['content'],
      deleted: map['deleted'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tip_id': tipId,
      'user_id': userId,
      'tip_date': tipDate.toIso8601String().split('T')[0],
      'content': content,
      'deleted': deleted ? 1 : 0,
    };
  }
}
