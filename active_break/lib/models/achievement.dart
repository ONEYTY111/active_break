class Achievement {
  final int achievementId;
  final String name;
  final String description;
  final String icon;
  final String type;
  final int targetValue;
  final DateTime createdAt;
  final bool deleted;

  Achievement({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.targetValue,
    required this.createdAt,
    this.deleted = false,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      achievementId: map['achievement_id'] ?? 0,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      type: map['type'] ?? '',
      targetValue: map['target_value'] ?? 0,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      deleted: (map['deleted'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'achievement_id': achievementId,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type,
      'target_value': targetValue,
      'created_at': createdAt.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'Achievement{achievementId: $achievementId, name: $name, description: $description, icon: $icon, type: $type, targetValue: $targetValue, createdAt: $createdAt, deleted: $deleted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement && other.achievementId == achievementId;
  }

  @override
  int get hashCode => achievementId.hashCode;
}