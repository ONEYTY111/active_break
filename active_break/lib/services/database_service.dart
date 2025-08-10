import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user.dart';
import '../models/check_in.dart';
import '../models/physical_activity.dart';
import '../models/reminder_and_tips.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _initialized = false;

  Future<Database> get database async {
    if (!_initialized) {
      await _initializeDatabaseFactory();
      _initialized = true;
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> _initializeDatabaseFactory() async {
    if (kIsWeb) {
      // For web platform, initialize the database factory
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('Database factory initialized for web platform');
    }
  }

  Future<Database> _initDatabase() async {
    try {
      String path;

      if (kIsWeb) {
        // For web platform, use a simple path
        path = 'reminder.db';
        print('Web platform detected, using path: $path');
      } else {
        // For mobile platforms, use documents directory
        Directory documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, 'reminder.db');
        print('Mobile platform detected, database path: $path');
      }

      // Check if database exists (only for non-web platforms)
      bool exists = false;
      if (!kIsWeb) {
        exists = await databaseExists(path);
        print('Database exists: $exists');

        if (!exists) {
          print('Copying database from assets...');
          // Copy from assets
          ByteData data = await rootBundle.load('assets/database/reminder.db');
          List<int> bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          await File(path).writeAsBytes(bytes);
          print('Database copied successfully');
        }
      }

      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onOpen: (db) async {
          // For web platform, create tables if they don't exist
          if (kIsWeb) {
            await _createTablesIfNotExist(db);
          }
          // Run migrations for all platforms
          await _migrate(db);
        },
      );
      print('Database opened successfully at path: $path');

      // Test the database connection
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
      print('Users table test query result: $result');

      // Print all tables for debugging
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      print('Available tables: $tables');

      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Database is copied from assets, so no need to create tables
    if (kIsWeb) {
      await _createTablesIfNotExist(db);
    }
  }


  Future<void> _migrate(Database db) async {
    try {
      // 1) Ensure users table has 'birthday' column
      final columns = await db.rawQuery("PRAGMA table_info(users)");
      final hasBirthday = columns.any((col) =>
          (col['name']?.toString().toLowerCase() ?? '') == 'birthday');
      if (!hasBirthday) {
        await db.execute('ALTER TABLE users ADD COLUMN birthday DATE');
      }

      // 2) Ensure i18n table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS t_physical_activities_i18n (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          activity_type_id INTEGER NOT NULL,
          language_code VARCHAR(10) NOT NULL,
          name VARCHAR(100) NOT NULL,
          description TEXT NOT NULL,
          FOREIGN KEY (activity_type_id) REFERENCES t_physical_activities(activity_type_id),
          UNIQUE(activity_type_id, language_code)
        )
      ''');

      // 3) Seed i18n data
      await _insertI18nData(db);
    } catch (e) {
      debugPrint('Migration error: $e');
    }
  }

  Future<void> _createTablesIfNotExist(Database db) async {
    // Create users table with birthday field
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        phone VARCHAR(20),
        gender VARCHAR(10),
        avatar_url TEXT,
        birthday DATE,
        last_login_time TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted BOOLEAN DEFAULT FALSE
      )
    ''');

    // Create check-in table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS t_check_in (
        checkin_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        checkin_date DATE NOT NULL,
        checkin_time TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (user_id) REFERENCES users(user_id)
      )
    ''');

    // Create user checkin streaks table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS t_user_checkin_streaks (
        user_id INTEGER NOT NULL PRIMARY KEY,
        current_streak INTEGER NOT NULL DEFAULT 0,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        total_checkin INTEGER NOT NULL DEFAULT 0,
        last_checkin_date DATE NOT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (user_id) REFERENCES users(user_id)
      )
    ''');

    // Create physical activities table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS t_physical_activities (
        activity_type_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(100) NOT NULL,
        description TEXT NOT NULL,
        calories_per_minute INTEGER NOT NULL,
        default_duration INTEGER NOT NULL,
        icon_url VARCHAR(255),
        deleted BOOLEAN DEFAULT FALSE
      )
    ''');

    // Create i18n physical activities table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS t_physical_activities_i18n (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        activity_type_id INTEGER NOT NULL,
        language_code VARCHAR(10) NOT NULL,
        name VARCHAR(100) NOT NULL,
        description TEXT NOT NULL,
        FOREIGN KEY (activity_type_id) REFERENCES t_physical_activities(activity_type_id),
        UNIQUE(activity_type_id, language_code)
      )
    ''');

    // Create activity records table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS t_activi_record (
        record_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        activity_type_id INTEGER NOT NULL,
        duration_minutes INTEGER NOT NULL,
        calories_burned INTEGER NOT NULL,
        begin_time TIMESTAMP NOT NULL,
        end_time TIMESTAMP NOT NULL,
        deleted BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (user_id) REFERENCES users(user_id),
        FOREIGN KEY (activity_type_id) REFERENCES t_physical_activities(activity_type_id)
      )
    ''');

    // Create reminder settings table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reminder_settings (
        reminder_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        activity_type_id INTEGER NOT NULL,
        enabled BOOLEAN NOT NULL DEFAULT TRUE,
        interval_value INTEGER NOT NULL,
        interval_week INTEGER NOT NULL,
        start_time TIMESTAMP NOT NULL,
        end_time TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (user_id) REFERENCES users(user_id),
        FOREIGN KEY (activity_type_id) REFERENCES t_physical_activities(activity_type_id)
      )
    ''');

    // Create user tips table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_tips (
        tip_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tip_date DATE NOT NULL,
        content TEXT NOT NULL,
        deleted BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (user_id) REFERENCES users(user_id)
      )
    ''');

    // Insert default physical activities
    await _insertDefaultActivities(db);
    
    // Insert i18n data
    await _insertI18nData(db);
  }

  Future<void> _insertI18nData(Database db) async {
    try {
      // Insert Chinese activity names
      await db.execute('''
        INSERT OR REPLACE INTO t_physical_activities_i18n (activity_type_id, language_code, name, description) VALUES
        (1, 'zh', '拉伸', '简单的拉伸运动，适合日常锻炼'),
        (2, 'zh', '跑步', '中等强度的跑步运动，燃烧更多卡路里'),
        (3, 'zh', '俯卧撑', '上肢力量训练，增强胸肌和手臂力量'),
        (4, 'zh', '深蹲', '下肢力量训练，增强腿部和臀部肌肉'),
        (5, 'zh', '平板支撑', '核心力量训练，增强腹部和背部肌肉'),
        (6, 'zh', '跳绳', '全身有氧运动，提高心肺功能'),
        (7, 'zh', '仰卧起坐', '腹部肌肉训练，增强核心力量'),
        (8, 'zh', '开合跳', '全身有氧运动，快速燃烧卡路里')
      ''');

      // Insert English activity names  
      await db.execute('''
        INSERT OR REPLACE INTO t_physical_activities_i18n (activity_type_id, language_code, name, description) VALUES
        (1, 'en', 'Walking', 'Simple walking exercise, suitable for daily workout'),
        (2, 'en', 'Running', 'Moderate intensity running exercise, burns more calories'),
        (3, 'en', 'Push-ups', 'Upper body strength training, strengthens chest and arm muscles'),
        (4, 'en', 'Squats', 'Lower body strength training, strengthens leg and glute muscles'),
        (5, 'en', 'Plank', 'Core strength training, strengthens abdominal and back muscles'),
        (6, 'en', 'Jump Rope', 'Full-body cardio exercise, improves cardiovascular fitness'),
        (7, 'en', 'Sit-ups', 'Abdominal muscle training, strengthens core strength'),
        (8, 'en', 'Jumping Jacks', 'Full-body cardio exercise, burns calories quickly')
      ''');
    } catch (e) {
      debugPrint('Error inserting i18n data: $e');
    }
  }

  Future<void> _insertDefaultActivities(Database db) async {
    final activities = [
      {
        'name': '拉伸',
        'description': '通过拉伸运动提高身体柔韧性，缓解肌肉紧张',
        'calories_per_minute': 3,
        'default_duration': 15,
        'icon_url': '58718',
      },
      {
        'name': '慢跑',
        'description': '有氧运动，提高心肺功能，燃烧卡路里',
        'calories_per_minute': 10,
        'default_duration': 30,
        'icon_url': '58724',
      },
      {
        'name': '跳绳',
        'description': '全身有氧运动，提高协调性和心肺功能',
        'calories_per_minute': 12,
        'default_duration': 20,
        'icon_url': '59469',
      },
      {
        'name': '步行',
        'description': '低强度有氧运动，适合所有年龄段',
        'calories_per_minute': 4,
        'default_duration': 45,
        'icon_url': '58723',
      },
      {
        'name': '单车',
        'description': '有氧运动，锻炼腿部肌肉，提高心肺功能',
        'calories_per_minute': 8,
        'default_duration': 40,
        'icon_url': '58721',
      },
      {
        'name': '椭圆机',
        'description': '全身有氧运动，低冲击性，保护关节',
        'calories_per_minute': 9,
        'default_duration': 35,
        'icon_url': '57735',
      },
    ];

    for (final activity in activities) {
      await db.insert(
        't_physical_activities',
        activity,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final db = await database;
      print('Database initialized, querying for email: $email');
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ? AND deleted = ?',
        whereArgs: [email, 0],
      );
      print('Query result for email $email: ${maps.length} records found');

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error in getUserByEmail: $e');
      rethrow;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    try {
      final db = await database;
      print('Database initialized, querying for username: $username');
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'username = ? AND deleted = ?',
        whereArgs: [username, 0],
      );
      print(
        'Query result for username $username: ${maps.length} records found',
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error in getUserByUsername: $e');
      rethrow;
    }
  }

  Future<User?> getUserById(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'user_id = ? AND deleted = ?',
      whereArgs: [userId, 0],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
  }

  // Check-in operations
  Future<int> insertCheckIn(CheckIn checkIn) async {
    final db = await database;
    return await db.insert('t_check_in', checkIn.toMap());
  }

  Future<CheckIn?> getTodayCheckIn(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      't_check_in',
      where: 'user_id = ? AND checkin_date = ? AND deleted = ?',
      whereArgs: [userId, today, 0],
    );

    if (maps.isNotEmpty) {
      return CheckIn.fromMap(maps.first);
    }
    return null;
  }

  Future<UserCheckinStreak?> getUserCheckinStreak(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      't_user_checkin_streaks',
      where: 'user_id = ? AND deleted = ?',
      whereArgs: [userId, 0],
    );

    if (maps.isNotEmpty) {
      return UserCheckinStreak.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertOrUpdateCheckinStreak(UserCheckinStreak streak) async {
    final db = await database;
    final existing = await getUserCheckinStreak(streak.userId);

    if (existing != null) {
      return await db.update(
        't_user_checkin_streaks',
        streak.toMap(),
        where: 'user_id = ?',
        whereArgs: [streak.userId],
      );
    } else {
      return await db.insert('t_user_checkin_streaks', streak.toMap());
    }
  }

  // Physical activities operations
  Future<List<PhysicalActivity>> getAllPhysicalActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      't_physical_activities',
      where: 'deleted = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) {
      return PhysicalActivity.fromMap(maps[i]);
    });
  }

  Future<PhysicalActivity?> getPhysicalActivityById(int activityTypeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      't_physical_activities',
      where: 'activity_type_id = ? AND deleted = ?',
      whereArgs: [activityTypeId, 0],
    );

    if (maps.isNotEmpty) {
      return PhysicalActivity.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePhysicalActivity(PhysicalActivity activity) async {
    final db = await database;
    return await db.update(
      't_physical_activities',
      activity.toMap(),
      where: 'activity_type_id = ?',
      whereArgs: [activity.activityTypeId],
    );
  }

  // Activity records operations
  Future<int> insertActivityRecord(ActivityRecord record) async {
    final db = await database;
    return await db.insert('t_activi_record', record.toMap());
  }

  Future<List<ActivityRecord>> getRecentActivityRecords(
    int userId, {
    int limit = 10,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      't_activi_record',
      where: 'user_id = ? AND deleted = ?',
      whereArgs: [userId, 0],
      orderBy: 'begin_time DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });
  }

  Future<List<ActivityRecord>> getActivityRecordsByDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      't_activi_record',
      where:
          'user_id = ? AND begin_time >= ? AND begin_time <= ? AND deleted = ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        0,
      ],
      orderBy: 'begin_time DESC',
    );

    return List.generate(maps.length, (i) {
      return ActivityRecord.fromMap(maps[i]);
    });
  }

  // Reminder settings operations
  Future<int> insertOrUpdateReminderSetting(ReminderSetting setting) async {
    final db = await database;
    final existing = await getReminderSetting(
      setting.userId,
      setting.activityTypeId,
    );

    if (existing != null) {
      return await db.update(
        'reminder_settings',
        setting.toMap(),
        where: 'user_id = ? AND activity_type_id = ?',
        whereArgs: [setting.userId, setting.activityTypeId],
      );
    } else {
      return await db.insert('reminder_settings', setting.toMap());
    }
  }

  Future<ReminderSetting?> getReminderSetting(
    int userId,
    int activityTypeId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminder_settings',
      where: 'user_id = ? AND activity_type_id = ? AND deleted = ?',
      whereArgs: [userId, activityTypeId, 0],
    );

    if (maps.isNotEmpty) {
      return ReminderSetting.fromMap(maps.first);
    }
    return null;
  }

  // User tips operations
  Future<int> insertUserTip(UserTip tip) async {
    final db = await database;
    return await db.insert('user_tips', tip.toMap());
  }

  Future<List<UserTip>> getTodayUserTips(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'user_tips',
      where: 'user_id = ? AND tip_date = ? AND deleted = ?',
      whereArgs: [userId, today, 0],
      orderBy: 'tip_id DESC',
      limit: 3,
    );

    return List.generate(maps.length, (i) {
      return UserTip.fromMap(maps[i]);
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
