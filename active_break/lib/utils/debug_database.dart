/**
 * @Description: Database debugging utility for checking activity records and weekly data
 * @className: DatabaseDebugger
 * @author Author
 * @date 2024-12-25 Current time
 * @company: Xi'an Boda Software Co., Ltd.
 * @copyright: Copyright (c) 2024
 * @version V1.0
 */

import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/physical_activity.dart';

class DatabaseDebugger {
  static final DatabaseService _databaseService = DatabaseService();

  /**
   * Debug weekly records data
   * @author Author
   * @date 2024-12-25 Current time
   * @param userId User ID
   * @return Future<void>
   */
  static Future<void> debugWeeklyRecords(int userId) async {
    try {
      debugPrint('=== Starting Weekly Records Debug ===');
      debugPrint('User ID: $userId');
      
      // First, check all records in database
      await debugAllRecords();
      
      final now = DateTime.now();
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
        0, 0, 0, 0,
      );
      final endOfWeek = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + 6,
        23, 59, 59, 999,
      );
      
      debugPrint('Current time: $now');
      debugPrint('Start of week: $startOfWeek');
      debugPrint('End of week: $endOfWeek');
      debugPrint('Start of week ISO: ${startOfWeek.toIso8601String()}');
      debugPrint('End of week ISO: ${endOfWeek.toIso8601String()}');
      
      // Check all activity records for this user
      await debugAllUserRecords(userId);
      
      // Check weekly records using the same logic as ActivityProvider
      final weeklyRecords = await _databaseService.getActivityRecordsByDateRange(
        userId,
        startOfWeek,
        endOfWeek,
      );
      
      debugPrint('Weekly records count: ${weeklyRecords.length}');
      
      if (weeklyRecords.isEmpty) {
        debugPrint('No weekly records found!');
      } else {
        for (int i = 0; i < weeklyRecords.length; i++) {
          final record = weeklyRecords[i];
          debugPrint('Record $i:');
          debugPrint('  - Activity Type ID: ${record.activityTypeId}');
          debugPrint('  - Duration: ${record.durationMinutes} minutes');
          debugPrint('  - Calories: ${record.caloriesBurned}');
          debugPrint('  - Begin Time: ${record.beginTime}');
          debugPrint('  - End Time: ${record.endTime}');
          debugPrint('  - Begin Time ISO: ${record.beginTime.toIso8601String()}');
        }
      }
      
      debugPrint('=== Weekly Records Debug Complete ===');
    } catch (e) {
      debugPrint('Error in debugWeeklyRecords: $e');
    }
  }

  /**
   * Debug all records in database
   * @author Author
   * @date 2024-12-25 Current time
   * @return Future<void>
   */
  static Future<void> debugAllRecords() async {
    try {
      debugPrint('=== Checking All Records ===');
      
      final db = await _databaseService.database;
      
      // Get total count
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM t_activi_record WHERE deleted = 0',
      );
      final totalCount = countResult.first['count'] as int;
      debugPrint('Total activity records in database: $totalCount');
      
      if (totalCount == 0) {
        debugPrint('No activity records found in database!');
        return;
      }
      
      // Get all records
      final allRecords = await db.query(
        't_activi_record',
        where: 'deleted = 0',
        orderBy: 'begin_time DESC',
        limit: 10, // Limit to recent 10 records
      );
      
      debugPrint('Recent ${allRecords.length} records:');
      for (int i = 0; i < allRecords.length; i++) {
        final record = allRecords[i];
        debugPrint('Record ${i + 1}:');
        debugPrint('  - Record ID: ${record['record_id']}');
        debugPrint('  - User ID: ${record['user_id']}');
        debugPrint('  - Activity Type ID: ${record['activity_type_id']}');
        debugPrint('  - Duration: ${record['duration_minutes']} minutes');
        debugPrint('  - Calories: ${record['calories_burned']}');
        debugPrint('  - Begin Time (raw): ${record['begin_time']}');
        debugPrint('  - End Time (raw): ${record['end_time']}');
        
        // Try to parse the date
        try {
          final beginTime = DateTime.parse(record['begin_time'] as String);
          final endTime = DateTime.parse(record['end_time'] as String);
          debugPrint('  - Begin Time (parsed): $beginTime');
          debugPrint('  - End Time (parsed): $endTime');
        } catch (e) {
          debugPrint('  - Error parsing dates: $e');
        }
      }
      
      debugPrint('=== All Records Check Complete ===');
    } catch (e) {
      debugPrint('Error in debugAllRecords: $e');
    }
  }

  /**
   * Debug all user activity records
   * @author Author
   * @date 2024-12-25 Current time
   * @param userId User ID
   * @return Future<void>
   */
  static Future<void> debugAllUserRecords(int userId) async {
    try {
      debugPrint('=== Checking All User Records ===');
      
      final db = await _databaseService.database;
      
      // Get total count
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM t_activi_record WHERE user_id = ? AND deleted = 0',
        [userId],
      );
      final totalCount = countResult.first['count'] as int;
      debugPrint('Total activity records for user $userId: $totalCount');
      
      if (totalCount == 0) {
        debugPrint('No activity records found for this user!');
        return;
      }
      
      // Get all records
      final allRecords = await db.query(
        't_activi_record',
        where: 'user_id = ? AND deleted = 0',
        whereArgs: [userId],
        orderBy: 'begin_time DESC',
        limit: 10, // Limit to recent 10 records
      );
      
      debugPrint('Recent ${allRecords.length} records:');
      for (int i = 0; i < allRecords.length; i++) {
        final record = allRecords[i];
        debugPrint('Record ${i + 1}:');
        debugPrint('  - Record ID: ${record['record_id']}');
        debugPrint('  - Activity Type ID: ${record['activity_type_id']}');
        debugPrint('  - Duration: ${record['duration_minutes']} minutes');
        debugPrint('  - Calories: ${record['calories_burned']}');
        debugPrint('  - Begin Time (raw): ${record['begin_time']}');
        debugPrint('  - End Time (raw): ${record['end_time']}');
        
        // Try to parse the date
        try {
          final beginTime = DateTime.parse(record['begin_time'] as String);
          final endTime = DateTime.parse(record['end_time'] as String);
          debugPrint('  - Begin Time (parsed): $beginTime');
          debugPrint('  - End Time (parsed): $endTime');
        } catch (e) {
          debugPrint('  - Error parsing dates: $e');
        }
      }
      
      debugPrint('=== All User Records Check Complete ===');
    } catch (e) {
      debugPrint('Error in debugAllUserRecords: $e');
    }
  }

  /**
   * Debug database query with custom date range
   * @author Author
   * @date 2024-12-25 Current time
   * @param userId User ID
   * @param startDate Start date
   * @param endDate End date
   * @return Future<void>
   */
  static Future<void> debugCustomDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      debugPrint('=== Custom Date Range Debug ===');
      debugPrint('User ID: $userId');
      debugPrint('Start Date: $startDate');
      debugPrint('End Date: $endDate');
      debugPrint('Start Date ISO: ${startDate.toIso8601String()}');
      debugPrint('End Date ISO: ${endDate.toIso8601String()}');
      
      final db = await _databaseService.database;
      
      // Test the exact query used in getActivityRecordsByDateRange
      final List<Map<String, dynamic>> maps = await db.query(
        't_activi_record',
        where: 'user_id = ? AND begin_time >= ? AND begin_time <= ? AND deleted = ?',
        whereArgs: [
          userId,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
          0,
        ],
        orderBy: 'begin_time DESC',
      );
      
      debugPrint('Query result count: ${maps.length}');
      
      if (maps.isEmpty) {
        debugPrint('No records found in date range!');
        
        // Try a broader query to see what dates exist
        final allMaps = await db.query(
          't_activi_record',
          where: 'user_id = ? AND deleted = ?',
          whereArgs: [userId, 0],
          orderBy: 'begin_time DESC',
        );
        
        debugPrint('All user records count: ${allMaps.length}');
        if (allMaps.isNotEmpty) {
          debugPrint('Sample dates in database:');
          for (int i = 0; i < allMaps.length && i < 5; i++) {
            debugPrint('  - ${allMaps[i]['begin_time']}');
          }
        }
      } else {
        debugPrint('Found ${maps.length} records in date range:');
        for (int i = 0; i < maps.length; i++) {
          final record = maps[i];
          debugPrint('Record ${i + 1}: ${record['begin_time']} - ${record['duration_minutes']} min');
        }
      }
      
      debugPrint('=== Custom Date Range Debug Complete ===');
    } catch (e) {
      debugPrint('Error in debugCustomDateRange: $e');
    }
  }

  /**
   * Check if user exists in database
   * @author Author
   * @date 2024-12-25 Current time
   * @param userId User ID
   * @return Future<void>
   */
  static Future<void> debugUserExists(int userId) async {
    try {
      debugPrint('=== Checking User Existence ===');
      debugPrint('User ID: $userId');
      
      final db = await _databaseService.database;
      
      // Check if user exists
      final userResult = await db.query(
        'users',
        where: 'user_id = ? AND deleted = 0',
        whereArgs: [userId],
      );
      
      if (userResult.isEmpty) {
        debugPrint('ERROR: User with ID $userId does not exist!');
        
        // Check all users
        final allUsers = await db.query('users', where: 'deleted = 0');
        debugPrint('Available users in database:');
        for (var user in allUsers) {
          debugPrint('  - User ID: ${user['user_id']}, Username: ${user['username']}, Email: ${user['email']}');
        }
      } else {
        final user = userResult.first;
        debugPrint('User found: ID=${user['user_id']}, Username=${user['username']}, Email=${user['email']}');
      }
      
      debugPrint('=== User Existence Check Complete ===');
    } catch (e) {
      debugPrint('Error checking user existence: $e');
    }
  }

  /**
   * Insert test activity record for debugging
   * @author Author
   * @date 2024-12-25 Current time
   * @param userId User ID
   * @return Future<void>
   */
  static Future<void> insertTestRecord(int userId) async {
    try {
      debugPrint('=== Inserting Test Record ===');
      debugPrint('User ID: $userId');
      
      // First check if user exists
      await debugUserExists(userId);
      
      final now = DateTime.now();
      final testRecord = ActivityRecord(
        userId: userId,
        activityTypeId: 1, // Assuming activity type 1 exists
        durationMinutes: 30,
        caloriesBurned: 150,
        beginTime: now.subtract(const Duration(hours: 1)),
        endTime: now,
      );
      
      final recordId = await _databaseService.insertActivityRecord(testRecord);
      debugPrint('Test record inserted with ID: $recordId');
      debugPrint('=== Test Record Insertion Complete ===');
    } catch (e) {
      debugPrint('Error inserting test record: $e');
    }
  }
}