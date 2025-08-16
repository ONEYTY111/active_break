import 'package:flutter/material.dart';

class ActivityIcons {
  static const Map<String, IconData> _iconMap = {
    // 新的运动类型图标映射
    '肩颈拉伸': Icons.self_improvement,
    '交替抬膝': Icons.directions_run,
    '跳绳动作': Icons.sports,
    '原地步行': Icons.directions_walk,
    '眼睛运动': Icons.visibility,
    '开合跳': Icons.accessibility,
    '腹式呼吸训练': Icons.spa,
    '动态站姿转体': Icons.rotate_90_degrees_ccw,
    '小腿激活': Icons.trending_up,
    '脊柱调动': Icons.straighten,

    // 保留旧的映射以兼容
    '拉伸': Icons.accessibility_new,
    '慢跑': Icons.directions_run,
    '跳绳': Icons.sports_gymnastics,
    '步行': Icons.directions_walk,
    '单车': Icons.directions_bike,
    '椭圆机': Icons.fitness_center,
    'stretching': Icons.accessibility_new,
    'jogging': Icons.directions_run,
    'jump_rope': Icons.sports_gymnastics,
    'walking': Icons.directions_walk,
    'cycling': Icons.directions_bike,
    'elliptical': Icons.fitness_center,
  };

  static IconData getIcon(String activityName) {
    return _iconMap[activityName] ?? Icons.fitness_center;
  }

  static String getIconPath(String activityName) {
    // Return a string representation for database storage
    final iconData = getIcon(activityName);
    return iconData.codePoint.toString();
  }

  static IconData getIconFromPath(String iconPath) {
    if (iconPath.isEmpty || iconPath == '/') {
      return Icons.fitness_center;
    }

    try {
      final codePoint = int.parse(iconPath);
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.fitness_center;
    }
  }

  // Activity type to icon mapping for better organization
  static const Map<int, IconData> activityTypeIcons = {
    // 最新运动ID映射 (61-70)
    61: Icons.self_improvement, // 肩颈拉伸
    62: Icons.directions_run, // 交替抬膝
    63: Icons.sports, // 跳绳动作
    64: Icons.directions_walk, // 原地步行
    65: Icons.visibility, // 眼睛运动
    66: Icons.accessibility, // 开合跳
    67: Icons.spa, // 腹式呼吸训练
    68: Icons.rotate_90_degrees_ccw, // 动态站姿转体
    69: Icons.trending_up, // 小腿激活
    70: Icons.straighten, // 脊柱调动
    // Activity IDs 71-80
    71: Icons.self_improvement,
    72: Icons.directions_run,
    73: Icons.sports,
    74: Icons.directions_walk,
    75: Icons.visibility,
    76: Icons.accessibility,
    77: Icons.spa,
    78: Icons.rotate_90_degrees_ccw,
    79: Icons.trending_up,
    80: Icons.straighten,
  };

  static IconData getIconByActivityType(int activityTypeId) {
    return activityTypeIcons[activityTypeId] ?? Icons.fitness_center;
  }

  static IconData getFallbackIcon(String name) {
    // Heuristic: select icon by keywords
    final lower = name.toLowerCase();
    if (lower.contains('肩颈') ||
        lower.contains('拉伸') ||
        lower.contains('stretch'))
      return Icons.self_improvement;
    if (lower.contains('抬膝') || lower.contains('跑') || lower.contains('run'))
      return Icons.directions_run;
    if (lower.contains('跳绳') || lower.contains('jump_rope'))
      return Icons.sports_gymnastics;
    if (lower.contains('步行') || lower.contains('走') || lower.contains('walk'))
      return Icons.directions_walk;
    if (lower.contains('眼睛') || lower.contains('eye')) return Icons.visibility;
    if (lower.contains('开合跳') || lower.contains('jumping_jacks'))
      return Icons.sports_handball;
    if (lower.contains('呼吸') || lower.contains('breathing')) return Icons.air;
    if (lower.contains('转体') || lower.contains('twist'))
      return Icons.rotate_right;
    if (lower.contains('小腿') || lower.contains('calf'))
      return Icons.trending_up;
    if (lower.contains('脊柱') || lower.contains('spine'))
      return Icons.straighten;
    if (lower.contains('骑') || lower.contains('bike') || lower.contains('单车'))
      return Icons.directions_bike;
    return Icons.fitness_center;
  }

  // Color mapping for different activity types - 统一使用蓝色系提高可读性
  static const Map<int, Color> activityTypeColors = {
    // 最新运动ID颜色映射 (61-70) - 统一蓝色系
    61: Colors.blue, // 肩颈拉伸
    62: Colors.blue, // 交替抬膝
    63: Colors.blue, // 跳绳动作
    64: Colors.blue, // 原地步行
    65: Colors.blue, // 眼睛运动
    66: Colors.blue, // 开合跳
    67: Colors.blue, // 腹式呼吸训练
    68: Colors.blue, // 动态站姿转体
    69: Colors.blue, // 小腿激活
    70: Colors.blue, // 脊柱调动
    // 新增运动ID颜色映射 (71-80) - 统一蓝色系
    71: Colors.blue, // 肩颈拉伸
    72: Colors.blue, // 交替抬膝
    73: Colors.blue, // 跳绳动作
    74: Colors.blue, // 原地步行
    75: Colors.blue, // 眼睛运动
    76: Colors.blue, // 开合跳
    77: Colors.blue, // 腹式呼吸训练
    78: Colors.blue, // 动态站姿转体
    79: Colors.blue, // 小腿激活
    80: Colors.blue, // 脊柱调动
    // 运动ID颜色映射 (51-60) - 统一蓝色系
    51: Colors.blue, // 肩颈拉伸
    52: Colors.blue, // 交替抬膝
    53: Colors.blue, // 跳绳动作
    54: Colors.blue, // 原地步行
    55: Colors.blue, // 眼睛运动
    56: Colors.blue, // 开合跳
    57: Colors.blue, // 腹式呼吸训练
    58: Colors.blue, // 动态站姿转体
    59: Colors.blue, // 小腿激活
    60: Colors.blue, // 脊柱调动
    // 当前运动ID颜色映射 (31-40) - 统一蓝色系
    31: Colors.blue, // 肩颈拉伸
    32: Colors.blue, // 交替抬膝
    33: Colors.blue, // 跳绳动作
    34: Colors.blue, // 原地步行
    35: Colors.blue, // 眼睛运动
    36: Colors.blue, // 开合跳
    37: Colors.blue, // 腹式呼吸训练
    38: Colors.blue, // 动态站姿转体
    39: Colors.blue, // 小腿激活
    40: Colors.blue, // 脊柱调动
    // 之前的ID颜色映射 (21-30) - 统一蓝色系
    21: Colors.blue, // 肩颈拉伸
    22: Colors.blue, // 交替抬膝
    23: Colors.blue, // 跳绳动作
    24: Colors.blue, // 原地步行
    25: Colors.blue, // 眼睛运动
    26: Colors.blue, // 开合跳
    27: Colors.blue, // 腹式呼吸训练
    28: Colors.blue, // 动态站姿转体
    29: Colors.blue, // 小腿激活
    30: Colors.blue, // 脊柱调动
    // 保留旧的颜色映射以兼容 - 统一蓝色系
    1: Colors.blue, // 拉伸
    2: Colors.blue, // 慢跑
    3: Colors.blue, // 跳绳
    4: Colors.blue, // 步行
    5: Colors.blue, // 单车
    6: Colors.blue, // 椭圆机
  };

  static Color getColorByActivityType(int activityTypeId) {
    return activityTypeColors[activityTypeId] ?? Colors.grey;
  }
}
