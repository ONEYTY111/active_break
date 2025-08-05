import 'package:flutter/material.dart';

class ActivityIcons {
  static const Map<String, IconData> _iconMap = {
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
    1: Icons.accessibility_new,     // 拉伸
    2: Icons.directions_run,        // 慢跑
    3: Icons.sports_gymnastics,     // 跳绳
    4: Icons.directions_walk,       // 步行
    5: Icons.directions_bike,       // 单车
    6: Icons.fitness_center,        // 椭圆机
  };

  static IconData getIconByActivityType(int activityTypeId) {
    return activityTypeIcons[activityTypeId] ?? Icons.fitness_center;
  }

  // Color mapping for different activity types
  static const Map<int, Color> activityTypeColors = {
    1: Colors.green,      // 拉伸 - 绿色
    2: Colors.orange,     // 慢跑 - 橙色
    3: Colors.purple,     // 跳绳 - 紫色
    4: Colors.blue,       // 步行 - 蓝色
    5: Colors.red,        // 单车 - 红色
    6: Colors.teal,       // 椭圆机 - 青色
  };

  static Color getColorByActivityType(int activityTypeId) {
    return activityTypeColors[activityTypeId] ?? Colors.grey;
  }
}
