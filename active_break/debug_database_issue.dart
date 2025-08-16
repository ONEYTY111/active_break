import 'dart:io';
import 'package:flutter/widgets.dart';
import 'lib/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== 检查数据库内容 ===');
  
  final dbService = DatabaseService();
  final db = await dbService.database;
  
  print('\n1. 检查 t_physical_activities 表:');
  final activities = await db.query('t_physical_activities', orderBy: 'activity_type_id');
  for (final activity in activities) {
    print('ID: ${activity['activity_type_id']}, 名称: ${activity['name']}, 删除: ${activity['deleted']}');
  }
  
  print('\n2. 检查 t_physical_activities_i18n 表 (中文):');
  final i18nZh = await db.query('t_physical_activities_i18n', 
      where: 'language_code = ?', 
      whereArgs: ['zh'],
      orderBy: 'activity_type_id');
  for (final i18n in i18nZh) {
    print('活动ID: ${i18n['activity_type_id']}, 中文名: ${i18n['name']}, 描述: ${i18n['description']}');
  }
  
  print('\n3. 通过 getAllPhysicalActivities() 获取的数据:');
  final allActivities = await dbService.getAllPhysicalActivities();
  for (final activity in allActivities) {
    print('ID: ${activity.activityTypeId}, 名称: ${activity.name}');
  }
  
  print('\n4. 应用显示问题分析:');
  print('应用界面显示: 拉伸、跑步、俯卧撑、深蹲、平板支撑');
  print('数据库活动表: ${activities.map((a) => a['name']).join('、')}');
  print('中文i18n表: ${i18nZh.map((a) => a['name']).join('、')}');
  
  exit(0);
}