import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/services/database_service.dart';
import 'lib/models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== 检查登录状态 ===');
  
  // 检查SharedPreferences中的登录状态
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  final userId = prefs.getInt('user_id');
  
  print('SharedPreferences中的登录状态: $isLoggedIn');
  print('SharedPreferences中的用户ID: $userId');
  
  // 检查数据库中的用户
  final databaseService = DatabaseService();
  
  if (userId != null) {
    final user = await databaseService.getUserById(userId);
    print('数据库中的用户: $user');
    
    if (user != null) {
      // 检查该用户的打卡记录
      final checkIns = await databaseService.database.then((db) => 
        db.query('t_check_in', where: 'user_id = ?', whereArgs: [userId]));
      print('用户 $userId 的打卡记录数量: ${checkIns.length}');
      
      // 检查该用户的运动记录
      final records = await databaseService.database.then((db) => 
        db.query('t_activi_record', where: 'user_id = ?', whereArgs: [userId]));
      print('用户 $userId 的运动记录数量: ${records.length}');
    }
  }
  
  // 列出所有用户
  final allUsers = await databaseService.database.then((db) => 
    db.query('users'));
  print('数据库中所有用户:');
  for (var user in allUsers) {
    print('  用户ID: ${user['user_id']}, 用户名: ${user['username']}, 邮箱: ${user['email']}');
  }
  
  print('=== 检查完成 ===');
}