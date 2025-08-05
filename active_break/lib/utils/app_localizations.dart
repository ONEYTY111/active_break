import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
      
      // Reminder
      'reminder_settings': '提醒设置',
      'enable_reminder': '启用提醒',
      'interval_minutes': '间隔（分钟）',
      'start_time': '开始时间',
      'end_time': '结束时间',
      'save': '保存',
      'reminder_saved': '提醒设置已保存',
      
      // Check-in
      'check_in_success': '打卡成功！',
      'consecutive_days': '连续打卡',
      'days': '天',
      'already_checked_in': '今日已打卡',
      
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
      'register_failed': 'Registration failed, username or email may already exist',
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
      
      // Reminder
      'reminder_settings': 'Reminder Settings',
      'enable_reminder': 'Enable Reminder',
      'interval_minutes': 'Interval (minutes)',
      'start_time': 'Start Time',
      'end_time': 'End Time',
      'save': 'Save',
      'reminder_saved': 'Reminder settings saved',
      
      // Check-in
      'check_in_success': 'Check-in successful!',
      'consecutive_days': 'Consecutive days',
      'days': 'days',
      'already_checked_in': 'Already checked in today',
      
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

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
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
