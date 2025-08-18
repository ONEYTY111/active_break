import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      // App
      'app_name': '健身打卡',

      // Auth
      'login': '登录',
      'register': '注册',
      'logout': '退出登录',
      'email_or_username': '邮箱或用户名',
      'username': '用户名',
      'nickname': '昵称',
      'avatar': '头像',
      'change_avatar': '更换头像',
      'email': '邮箱',
      'phone': '手机号',
      'password': '密码',
      'confirm_password': '确认密码',
      'gender': '性别',
      'male': '男',
      'female': '女',
      'optional': '可选',
      'field_required': '此字段为必填项',
      'username_too_short': '用户名至少3个字符',
      'password_too_short': '密码至少6个字符',
      'passwords_not_match': '两次密码不一致',
      'invalid_email': '邮箱格式不正确',
      'login_failed': '登录失败，请检查用户名和密码',
      'register_failed': '注册失败，用户名或邮箱可能已存在',
      'no_account_register': '没有账号？立即注册',

      // Navigation
      'home': '首页',
      'exercise': '运动',
      'recommend': '推荐',
      'profile': '我的',
      'check_in': '打卡',

      // Home
      'recent_activities': '最近运动',
      'weekly_summary': '本周总结',
      'activity_trend': '运动趋势',
      'total_duration': '总时长',
      'total_calories': '总消耗',
      'minutes': '分钟',
      'calories': '卡路里',

      // Exercise
      'start': '开始',
      'stop': '停止',
      'set_reminder': '设置提醒',
      'timer_running': '计时中',
      'duration': '时长',
      'save_record': '保存记录',
      'record_saved': '运动记录已保存',
      'activity_auto_completed': '运动时间到，已自动完成！',

      // Reminder
      'reminder_settings': '提醒设置',
      'enable_reminder': '启用提醒',
      'interval_minutes': '间隔（分钟）',
      'start_time': '开始时间',
      'end_time': '结束时间',
      'save': '保存',
      'reminder_saved': '提醒设置已保存',
      'no_recent_activities': '暂无最近运动',
      'start_exercising_now': '现在开始运动吧！',
      'repeat_every': '重复间隔',
      'every_day': '每天',
      'every_2_days': '每2天',
      'every_3_days': '每3天',
      'weekly': '每周',

      // Check-in
      'check_in_success': '恭喜你完成打卡！',
      'check_in_congratulations': '太棒了！',
      'consecutive_days': '连续天数',
      'days': '天',
      'already_checked_in': '今天已经打过卡了',
      'keep_it_up': '继续保持！',
      'already_checked_in_subtitle': '今天已经完成打卡了，明天再来吧！',

      // Recommend
      'daily_tips': '每日健康建议',
      'no_tips_today': '今日暂无建议',

      // Profile
      'personal_info': '个人信息',
      'settings': '设置',
      'theme': '主题',
      'language': '语言',
      'light_mode': '浅色模式',
      'dark_mode': '深色模式',
      'system_mode': '跟随系统',
      'chinese': '中文',
      'english': 'English',
      'edit_profile': '编辑资料',
      'change_password': '修改密码',
      'current_password': '当前密码',
      'new_password': '新密码',
      'password_changed': '密码修改成功',
      'password_change_failed': '密码修改失败',
      'profile_updated': '资料更新成功',
      'profile_update_failed': '资料更新失败',
      'birthday': '生日',

      // Favorites
      'my_favorites': '我的收藏',
      'favorites': '收藏',
      'add_to_favorites': '添加到收藏',
      'remove_from_favorites': '取消收藏',
      'no_favorites': '暂无收藏内容',
      'no_favorites_subtitle': '收藏你喜欢的健康建议，方便随时查看',

      // Achievements
      'achievements': '成就',
      'my_achievements': '我的成就',
      'achievement_progress': '成就进度',
      'completed_achievements': '已达成',
      'uncompleted_achievements': '未达成',
      'achievement_unlocked': '成就解锁！',
      'achievement_completed': '成就达成',
      'no_achievements': '暂无成就',
      'no_achievements_subtitle': '完成运动和打卡来解锁成就吧！',
      'achievement_description': '成就描述',
      'achievement_reward': '成就奖励',
      'progress': '进度',
      'completed': '已完成',
      'in_progress': '进行中',
      'locked': '未解锁',
      'total': '总计',
      'completion_rate': '完成率',
      'no_achievements_yet': '暂无成就',
      'retry': '重试',
      'achievement_unlocked': '成就解锁！',
      'congratulations_achievement': '恭喜你达成了新成就！',

      'welcome_message': '让我们一起保持健康的生活方式！',
      'hello_user': '你好，{username}！',

      // Common
      'cancel': '取消',
      'confirm': '确认',
      'edit': '编辑',
      'delete': '删除',
      'loading': '加载中...',
      'error': '错误',
      'success': '成功',
      'warning': '警告',
      'info': '信息',
    },
    'en': {
      // App
      'app_name': 'Active Break',

      // Auth
      'login': 'Login',
      'register': 'Register',
      'logout': 'Logout',
      'email_or_username': 'Email or Username',
      'username': 'Username',
      'nickname': 'Nickname',
      'avatar': 'Avatar',
      'change_avatar': 'Change Avatar',
      'email': 'Email',
      'phone': 'Phone',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'optional': 'Optional',
      'field_required': 'This field is required',
      'username_too_short': 'Username must be at least 3 characters',
      'password_too_short': 'Password must be at least 6 characters',
      'passwords_not_match': 'Passwords do not match',
      'invalid_email': 'Invalid email format',
      'login_failed': 'Login failed, please check username and password',
      'register_failed':
          'Registration failed, username or email may already exist',
      'no_account_register': 'No account? Register now',

      // Navigation
      'home': 'Home',
      'exercise': 'Exercise',
      'recommend': 'Recommend',
      'profile': 'Profile',
      'check_in': 'Check In',

      // Home
      'recent_activities': 'Recent Activities',
      'weekly_summary': 'Weekly Summary',
      'activity_trend': 'Activity Trend',
      'total_duration': 'Total Duration',
      'total_calories': 'Total Calories',
      'minutes': 'minutes',
      'calories': 'calories',

      // Exercise
      'start': 'Start',
      'stop': 'Stop',
      'set_reminder': 'Set Reminder',
      'timer_running': 'Timer Running',
      'duration': 'Duration',
      'save_record': 'Save Record',
      'record_saved': 'Activity record saved',
      'activity_auto_completed':
          'Time\'s up! Activity completed automatically!',

      // Reminder
      'reminder_settings': 'Reminder Settings',
      'enable_reminder': 'Enable Reminder',
      'interval_minutes': 'Interval (minutes)',
      'start_time': 'Start Time',
      'end_time': 'End Time',
      'save': 'Save',
      'reminder_saved': 'Reminder settings saved',
      'no_recent_activities': 'No recent activities',
      'start_exercising_now': 'Start exercising now!',
      'repeat_every': 'Repeat every',
      'every_day': 'Every day',
      'every_2_days': 'Every 2 days',
      'every_3_days': 'Every 3 days',
      'weekly': 'Weekly',

      // Check-in
      'check_in_success': 'Congratulations on your check-in!',
      'check_in_congratulations': 'Awesome!',
      'consecutive_days': 'Consecutive days',
      'days': 'days',
      'already_checked_in': 'Already checked in today',
      'keep_it_up': 'Keep it up!',
      'already_checked_in_subtitle':
          'You have already checked in today, come back tomorrow!',

      // Recommend
      'daily_tips': 'Daily Health Tips',
      'no_tips_today': 'No tips for today',

      // Profile
      'personal_info': 'Personal Information',
      'settings': 'Settings',
      'theme': 'Theme',
      'language': 'Language',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'system_mode': 'System Mode',
      'chinese': '中文',
      'english': 'English',
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',
      'current_password': 'Current Password',
      'new_password': 'New Password',
      'password_changed': 'Password changed successfully',
      'password_change_failed': 'Password change failed',
      'profile_updated': 'Profile updated successfully',
      'profile_update_failed': 'Profile update failed',
      'birthday': 'Birthday',

      // Favorites
      'my_favorites': 'My Favorites',
      'favorites': 'Favorites',
      'add_to_favorites': 'Add to Favorites',
      'remove_from_favorites': 'Remove from Favorites',
      'no_favorites': 'No favorites yet',
      'no_favorites_subtitle': 'Save your favorite health tips for easy access',

      // Achievements
      'achievements': 'Achievements',
      'my_achievements': 'My Achievements',
      'achievement_progress': 'Achievement Progress',
      'completed_achievements': 'Completed',
      'uncompleted_achievements': 'Uncompleted',
      'achievement_unlocked': 'Achievement Unlocked!',
      'achievement_completed': 'Achievement Completed',
      'no_achievements': 'No achievements yet',
      'no_achievements_subtitle':
          'Complete exercises and check-ins to unlock achievements!',
      'achievement_description': 'Achievement Description',
      'achievement_reward': 'Achievement Reward',
      'progress': 'Progress',
      'completed': 'Completed',
      'in_progress': 'In Progress',
      'locked': 'Locked',
      'total': 'Total',
      'completion_rate': 'Completion Rate',
      'no_achievements_yet': 'No achievements yet',
      'retry': 'Retry',
      'achievement_unlocked': 'Achievement Unlocked!',
      'congratulations_achievement': 'Congratulations on your new achievement!',

      'welcome_message': 'Let\'s maintain a healthy lifestyle together!',
      'hello_user': 'Hello, {username}!',

      // Common
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'edit': 'Edit',
      'delete': 'Delete',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Info',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['zh', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
