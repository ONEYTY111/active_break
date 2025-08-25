import 'package:flutter/material.dart';

class ActivityIcons {
  static const Map<String, IconData> _iconMap = {
    // English activity type icon mapping
     'Neck and Shoulder Stretch': Icons.self_improvement,
     'Alternating Knee Lifts': Icons.directions_run,
     'Jump Rope Action': Icons.sports,
     'Walking in Place': Icons.directions_walk,
     'Eye Exercises': Icons.visibility,
     'Jumping Jacks': Icons.accessibility,
     'Abdominal Breathing Training': Icons.spa,
     'Dynamic Standing Twist': Icons.rotate_90_degrees_ccw,
     'Calf Activation': Icons.trending_up,
     'Spinal Mobilization': Icons.straighten,

   // General activity type mapping
   'Stretch': Icons.accessibility_new,
   'Jogging': Icons.directions_run,
   'Jump Rope': Icons.sports_gymnastics,
   'Walking': Icons.directions_walk,
   'Cycling': Icons.directions_bike,
   'Elliptical': Icons.fitness_center,
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
    // Latest activity ID mapping (61-70)
  61: Icons.self_improvement, // Neck and shoulder stretch
  62: Icons.directions_run, // Alternating knee lifts
  63: Icons.sports, // Jump rope
  64: Icons.directions_walk, // Walking in place
  65: Icons.visibility, // Eye exercises
  66: Icons.accessibility, // Jumping jacks
  67: Icons.spa, // Abdominal breathing
  68: Icons.rotate_90_degrees_ccw, // Dynamic standing twist
  69: Icons.trending_up, // Calf activation
  70: Icons.straighten, // Spine mobilization
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
    if (lower.contains('neck') ||
        lower.contains('shoulder') ||
        lower.contains('stretch')) return Icons.self_improvement;
    if (lower.contains('knee') || lower.contains('run') || lower.contains('jog'))
      return Icons.directions_run;
    if (lower.contains('jump') || lower.contains('rope'))
      return Icons.sports;
    if (lower.contains('walk') || lower.contains('step'))
      return Icons.directions_walk;
    if (lower.contains('eye') || lower.contains('vision')) return Icons.visibility;
    if (lower.contains('jumping') || lower.contains('jacks'))
      return Icons.accessibility;
    if (lower.contains('breath') || lower.contains('breathing')) return Icons.air;
    if (lower.contains('twist') || lower.contains('rotation'))
      return Icons.rotate_90_degrees_ccw;
    if (lower.contains('calf') || lower.contains('activation'))
      return Icons.trending_up;
    if (lower.contains('spine') || lower.contains('spinal'))
      return Icons.straighten;
    if (lower.contains('bike') || lower.contains('cycling') || lower.contains('bicycle'))
      return Icons.directions_bike;
    return Icons.fitness_center;
  }

  // Color mapping for different activity types - unified blue theme for better readability
  static const Map<int, Color> activityTypeColors = {
    // Latest activity ID color mapping (61-70) - unified blue theme
    61: Colors.blue, // Neck and shoulder stretch
    62: Colors.blue, // Alternating knee lifts
    63: Colors.blue, // Jump rope
    64: Colors.blue, // Walking in place
    65: Colors.blue, // Eye exercises
    66: Colors.blue, // Jumping jacks
    67: Colors.blue, // Abdominal breathing
    68: Colors.blue, // Dynamic standing twist
    69: Colors.blue, // Calf activation
    70: Colors.blue, // Spine mobilization
    // New activity ID color mapping (71-80) - unified blue theme
    71: Colors.blue, // Neck and shoulder stretch
    72: Colors.blue, // Alternating knee lifts
    73: Colors.blue, // Jump rope
    74: Colors.blue, // Walking in place
    75: Colors.blue, // Eye exercises
    76: Colors.blue, // Jumping jacks
    77: Colors.blue, // Abdominal breathing
    78: Colors.blue, // Dynamic standing twist
    79: Colors.blue, // Calf activation
    80: Colors.blue, // Spine mobilization
    // Activity ID color mapping (51-60) - unified blue theme
    51: Colors.blue, // Neck and shoulder stretch
    52: Colors.blue, // Alternating knee lifts
    53: Colors.blue, // Jump rope
    54: Colors.blue, // Walking in place
    55: Colors.blue, // Eye exercises
    56: Colors.blue, // Jumping jacks
    57: Colors.blue, // Abdominal breathing
    58: Colors.blue, // Dynamic standing twist
    59: Colors.blue, // Calf activation
    60: Colors.blue, // Spine mobilization
    // Current activity ID color mapping (31-40) - unified blue theme
    31: Colors.blue, // Neck and shoulder stretch
    32: Colors.blue, // Alternating knee lifts
    33: Colors.blue, // Jump rope
    34: Colors.blue, // Walking in place
    35: Colors.blue, // Eye exercises
    36: Colors.blue, // Jumping jacks
    37: Colors.blue, // Abdominal breathing
    38: Colors.blue, // Dynamic standing twist
    39: Colors.blue, // Calf activation
    40: Colors.blue, // Spine mobilization
    // Previous ID color mapping (21-30) - unified blue theme
    21: Colors.blue, // Neck and shoulder stretch
    22: Colors.blue, // Alternating knee lifts
    23: Colors.blue, // Jump rope
    24: Colors.blue, // Walking in place
    25: Colors.blue, // Eye exercises
    26: Colors.blue, // Jumping jacks
    27: Colors.blue, // Abdominal breathing
    28: Colors.blue, // Dynamic standing twist
    29: Colors.blue, // Calf activation
    30: Colors.blue, // Spine mobilization
    // Keep old color mapping for compatibility - unified blue theme
    1: Colors.blue, // Stretching
    2: Colors.blue, // Jogging
    3: Colors.blue, // Jump rope
    4: Colors.blue, // Walking
    5: Colors.blue, // Cycling
    6: Colors.blue, // Elliptical
  };

  static Color getColorByActivityType(int activityTypeId) {
    return activityTypeColors[activityTypeId] ?? Colors.grey;
  }
}
