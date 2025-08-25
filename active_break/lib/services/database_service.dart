import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
      final hasBirthday = columns.any(
        (col) => (col['name']?.toString().toLowerCase() ?? '') == 'birthday',
      );
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

      // 3) Clean up duplicate activity data
      await _cleanupDuplicateActivities(db);
      
      // 4) Ensure favorites table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_favorites (
          favorite_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          tip_id INTEGER NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          deleted BOOLEAN DEFAULT FALSE,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (tip_id) REFERENCES user_tips(tip_id),
          UNIQUE(user_id, tip_id)
        )
      ''');
      
      // 5) Ensure achievements table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS achievements (
          achievement_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          name VARCHAR(100) NOT NULL,
          description TEXT NOT NULL,
          icon VARCHAR(50) NOT NULL,
          type VARCHAR(50) NOT NULL,
          target_value INTEGER NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          deleted BOOLEAN DEFAULT FALSE
        )
      ''');

      // 6) Ensure achievements i18n table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS achievements_i18n (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          achievement_id INTEGER NOT NULL,
          language_code VARCHAR(10) NOT NULL,
          name VARCHAR(100) NOT NULL,
          description TEXT NOT NULL,
          FOREIGN KEY (achievement_id) REFERENCES achievements(achievement_id),
          UNIQUE(achievement_id, language_code)
        )
      ''');

      // 7) Ensure user achievements table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_achievements (
          user_achievement_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          achievement_id INTEGER NOT NULL,
          achieved_at TIMESTAMP,
          current_progress INTEGER DEFAULT 0,
          is_achieved BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          deleted BOOLEAN DEFAULT FALSE,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (achievement_id) REFERENCES achievements(achievement_id),
          UNIQUE(user_id, achievement_id)
        )
      ''');

      // 8) Ensure reminder logs table exists
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminder_logs (
          log_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          activity_type_id INTEGER NOT NULL,
          triggered_at INTEGER NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(user_id),
          FOREIGN KEY (activity_type_id) REFERENCES t_physical_activities(activity_type_id)
        )
      ''');
      
      // 9) Insert predefined achievements
      debugPrint('=== Starting to insert predefined achievements ===');
      await _insertPredefinedAchievements(db);
      debugPrint('=== Predefined achievements insertion completed ===');
      
      // 10) Update activity data and i18n table (insert only when no data exists)
      await _updateActivitiesAndI18nData(db);
      
      debugPrint('Database migration completed, activity data updated');
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

    // Create user favorites table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_favorites (
        favorite_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tip_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (user_id) REFERENCES users(user_id),
        FOREIGN KEY (tip_id) REFERENCES user_tips(tip_id),
        UNIQUE(user_id, tip_id)
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
        (1, 'zh', '肩颈拉伸', '缓解肩颈疲劳，改善颈椎健康'),
        (2, 'zh', '交替抬膝', '提高心率，锻炼腿部肌肉'),
        (3, 'zh', '跳绳动作', '全身有氧运动，提高协调性'),
        (4, 'zh', '原地步行', '低强度有氧运动，适合办公室锻炼'),
        (5, 'zh', '眼睛运动', '缓解眼部疲劳，保护视力健康'),
        (6, 'zh', '开合跳', '全身有氧运动，快速燃烧卡路里'),
        (7, 'zh', '腹式呼吸训练', '放松身心，改善呼吸质量'),
        (8, 'zh', '动态站姿转体', '锻炼腰腹核心，改善脊柱灵活性'),
        (9, 'zh', '小腿激活', '激活小腿肌肉，促进血液循环'),
        (10, 'zh', '脊柱调动', '改善脊柱健康，缓解背部僵硬')
      ''');

      // Insert English activity names
      await db.execute('''
        INSERT OR REPLACE INTO t_physical_activities_i18n (activity_type_id, language_code, name, description) VALUES
        (1, 'en', 'Neck & Shoulder Stretch', 'Relieves neck and shoulder fatigue, improves cervical health'),
        (2, 'en', 'Alternating Knee Lifts', 'Increases heart rate, exercises leg muscles'),
        (3, 'en', 'Jump Rope Motion', 'Full-body cardio exercise, improves coordination'),
        (4, 'en', 'Walking in Place', 'Low-intensity cardio exercise, suitable for office workouts'),
        (5, 'en', 'Eye Exercises', 'Relieves eye fatigue, protects vision health'),
        (6, 'en', 'Jumping Jacks', 'Full-body cardio exercise, burns calories quickly'),
        (7, 'en', 'Diaphragmatic Breathing', 'Relaxes body and mind, improves breathing quality'),
        (8, 'en', 'Dynamic Standing Torso Twist', 'Exercises core muscles, improves spinal flexibility'),
        (9, 'en', 'Calf Activation', 'Activates calf muscles, promotes blood circulation'),
        (10, 'en', 'Spinal Mobility', 'Improves spinal health, relieves back stiffness')
      ''');
    } catch (e) {
      debugPrint('Error inserting i18n data: $e');
    }
  }

  Future<void> _insertDefaultActivities(Database db) async {
    debugPrint('Starting to insert default activity data...');
    final activities = [
      {
        'name': '肩颈拉伸',
        'description': '缓解肩颈疲劳，改善颈椎健康',
        'calories_per_minute': 2,
        'default_duration': 10,
        'icon_url': 'stretch_neck',
        'deleted': 0,
      },
      {
        'name': '交替抬膝',
        'description': '提高心率，锻炼腿部肌肉',
        'calories_per_minute': 6,
        'default_duration': 15,
        'icon_url': 'knee_lift',
        'deleted': 0,
      },
      {
        'name': '跳绳动作',
        'description': '全身有氧运动，提高协调性',
        'calories_per_minute': 12,
        'default_duration': 20,
        'icon_url': 'jump_rope',
        'deleted': 0,
      },
      {
        'name': '原地步行',
        'description': '低强度有氧运动，适合办公室锻炼',
        'calories_per_minute': 4,
        'default_duration': 15,
        'icon_url': 'walking_in_place',
        'deleted': 0,
      },
      {
        'name': '眼睛运动',
        'description': '缓解眼部疲劳，保护视力健康',
        'calories_per_minute': 1,
        'default_duration': 5,
        'icon_url': 'eye_exercise',
        'deleted': 0,
      },
      {
        'name': '开合跳',
        'description': '全身有氧运动，快速燃烧卡路里',
        'calories_per_minute': 10,
        'default_duration': 10,
        'icon_url': 'jumping_jacks',
        'deleted': 0,
      },
      {
        'name': '腹式呼吸训练',
        'description': '放松身心，改善呼吸质量',
        'calories_per_minute': 1,
        'default_duration': 8,
        'icon_url': 'breathing',
        'deleted': 0,
      },
      {
        'name': '动态站姿转体',
        'description': '锻炼腰腹核心，改善脊柱灵活性',
        'calories_per_minute': 3,
        'default_duration': 12,
        'icon_url': 'torso_twist',
        'deleted': 0,
      },
      {
        'name': '小腿激活',
        'description': '激活小腿肌肉，促进血液循环',
        'calories_per_minute': 2,
        'default_duration': 8,
        'icon_url': 'calf_raise',
        'deleted': 0,
      },
      {
        'name': '脊柱调动',
        'description': '改善脊柱健康，缓解背部僵硬',
        'calories_per_minute': 2,
        'default_duration': 10,
        'icon_url': 'spine_mobility',
        'deleted': 0,
      },
    ];

    for (final activity in activities) {
      try {
        final result = await db.insert(
          't_physical_activities',
          activity,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('Inserted activity data: ${activity['name']}, ID: $result');
      } catch (e) {
        debugPrint('Failed to insert activity data: ${activity['name']}, error: $e');
      }
    }
    
    // Verify insertion result
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM t_physical_activities');
    debugPrint('Activity data insertion completed, total count: ${count.first['count']}');
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
      orderBy: 'activity_type_id ASC',
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

  // Update activity data and i18n table (internal method)
  Future<void> _updateActivitiesAndI18nData(Database db) async {
    try {
      // Check if activity data already exists
      final existingActivities = await db.rawQuery(
        'SELECT COUNT(*) as count FROM t_physical_activities WHERE deleted = 0'
      );
      final activityCount = existingActivities.first['count'] as int;
      
      if (activityCount == 0) {
        // Insert only when no activity data exists
        debugPrint('No activity data in database, starting to insert default data...');
        await _insertDefaultActivities(db);
        await _insertI18nData(db);
        debugPrint('Default activity data and i18n table inserted');
      } else {
        debugPrint('Database already has $activityCount activity records, skipping insertion');
      }
    } catch (e) {
      debugPrint('Error checking or inserting activity data: $e');
    }
  }
  
  // Public update method
  Future<void> updateActivitiesData() async {
    final db = await database;
    await _updateActivitiesAndI18nData(db);
  }
  
  // Clean up duplicate activity data, keep only the latest 10 (internal method)
  Future<void> _cleanupDuplicateActivities(Database db) async {
    try {
      // Get all activity data, sorted by ID in descending order
      final activities = await db.rawQuery(
        'SELECT * FROM t_physical_activities WHERE deleted = 0 ORDER BY activity_type_id DESC'
      );
      
      if (activities.length > 10) {
        // Keep the latest 10, delete others
        final keepIds = activities.take(10).map((a) => a['activity_type_id']).toList();
        final keepIdsStr = keepIds.join(',');
        
        await db.execute(
          'UPDATE t_physical_activities SET deleted = 1 WHERE activity_type_id NOT IN ($keepIdsStr)'
        );
        
        // Also clean up corresponding i18n data
        await db.execute(
          'DELETE FROM t_physical_activities_i18n WHERE activity_type_id NOT IN ($keepIdsStr)'
        );
        
        debugPrint('Cleaned up duplicate activity data, kept the latest 10');
      } else {
        debugPrint('Activity data count is normal, no cleanup needed');
      }
    } catch (e) {
      debugPrint('Error occurred while cleaning up duplicate activity data: $e');
    }
  }
  
  // Clean up duplicate activity data, keep only the latest 10 (public method)
  Future<void> cleanupDuplicateActivities() async {
    final db = await database;
    await _cleanupDuplicateActivities(db);
  }

  Future<bool> overwriteDatabaseFromAsset({bool backup = true}) async {
    try {
      if (kIsWeb) {
        debugPrint('Web platform does not support overwriting database file from assets.');
        return false;
      }

      // Resolve database path in app documents directory
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final dbPath = join(documentsDirectory.path, 'reminder.db');

      // Close current db connection if opened
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Optional: backup existing db file
      final file = File(dbPath);
      if (backup && await file.exists()) {
        final backupPath = join(
          dirname(dbPath),
          'reminder_backup_${DateTime.now().millisecondsSinceEpoch}.db',
        );
        await file.copy(backupPath);
        debugPrint('Database backed up to: $backupPath');
      }

      // Copy asset db to target path (overwrite)
      final data = await rootBundle.load('assets/database/reminder.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes, flush: true);
      debugPrint('Database overwritten from assets to: $dbPath');

      // Reopen database via our standard initializer
      await database;
      return true;
    } catch (e) {
      debugPrint('Error overwriting database from asset: $e');
      return false;
    }
  }

  // Favorites related methods
  Future<void> addToFavorites(int userId, int tipId) async {
    final db = await database;
    await db.insert(
      'user_favorites',
      {
        'user_id': userId,
        'tip_id': tipId,
        'created_at': DateTime.now().toIso8601String(),
        'deleted': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFromFavorites(int userId, int tipId) async {
    final db = await database;
    await db.update(
      'user_favorites',
      {'deleted': 1},
      where: 'user_id = ? AND tip_id = ?',
      whereArgs: [userId, tipId],
    );
  }

  // Insert predefined achievements
  Future<void> _insertPredefinedAchievements(Database db) async {
    try {
      // Check if achievement data already exists
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM achievements');
      final achievementCount = count.first['count'] as int;
      
      if (achievementCount == 0) {
        // Insert predefined achievements
        final achievements = [
          {
            'name': '初来乍到',
            'description': '完成第一次打卡',
            'icon': '🎉',
            'type': 'checkin_count',
            'target_value': 1,
          },
          {
            'name': '坚持一周',
            'description': '连续打卡7天',
            'icon': '🔥',
            'type': 'checkin_streak',
            'target_value': 7,
          },
          {
            'name': '月度达人',
            'description': '连续打卡30天',
            'icon': '🏆',
            'type': 'checkin_streak',
            'target_value': 30,
          },
          {
            'name': '运动新手',
            'description': '完成第一次运动',
            'icon': '💪',
            'type': 'exercise_count',
            'target_value': 1,
          },
          {
            'name': '运动达人',
            'description': '连续运动7天',
            'icon': '🏃',
            'type': 'exercise_streak',
            'target_value': 7,
          },
          {
            'name': '卡路里杀手',
            'description': '累计消耗1000卡路里',
            'icon': '🔥',
            'type': 'calories_burned',
            'target_value': 1000,
          },
          {
            'name': '时间管理大师',
            'description': '累计运动时间达到10小时',
            'icon': '⏰',
            'type': 'exercise_duration',
            'target_value': 600, // 10 hours = 600 minutes
          },
        ];
        
        for (final achievement in achievements) {
          await db.insert('achievements', achievement);
        }
        
        // Insert achievement i18n data
        await _insertAchievementI18nData(db);
        
        debugPrint('Predefined achievements insertion completed, inserted ${achievements.length} achievements');
      } else {
        debugPrint('Achievement data already exists, skipping insertion');
      }
      
      // Check and insert i18n data regardless of whether achievement data exists
      await _insertAchievementI18nData(db);
    } catch (e) {
      debugPrint('Error occurred while inserting predefined achievements: $e');
    }
  }

  Future<void> _insertAchievementI18nData(Database db) async {
    try {
      debugPrint('=== Starting to check achievement i18n data ===');
      // Check if achievement i18n data already exists
      final count = await db.rawQuery('SELECT COUNT(*) as count FROM achievements_i18n');
      final i18nCount = count.first['count'] as int;
      debugPrint('Current achievement i18n data count: $i18nCount');
      
      if (i18nCount == 0) {
        // Achievement i18n data
        final achievementI18nData = [
          // First Timer
          {'achievement_id': 1, 'language_code': 'zh', 'name': '初来乍到', 'description': '完成第一次打卡'},
          {'achievement_id': 1, 'language_code': 'en', 'name': 'First Timer', 'description': 'Complete your first check-in'},
          
          // Week Warrior
          {'achievement_id': 2, 'language_code': 'zh', 'name': '坚持一周', 'description': '连续打卡7天'},
          {'achievement_id': 2, 'language_code': 'en', 'name': 'Week Warrior', 'description': 'Check in for 7 consecutive days'},
          
          // Monthly Master
          {'achievement_id': 3, 'language_code': 'zh', 'name': '月度达人', 'description': '连续打卡30天'},
          {'achievement_id': 3, 'language_code': 'en', 'name': 'Monthly Master', 'description': 'Check in for 30 consecutive days'},
          
          // Exercise Beginner
          {'achievement_id': 4, 'language_code': 'zh', 'name': '运动新手', 'description': '完成第一次运动'},
          {'achievement_id': 4, 'language_code': 'en', 'name': 'Exercise Beginner', 'description': 'Complete your first exercise'},
          
          // Exercise Expert
          {'achievement_id': 5, 'language_code': 'zh', 'name': '运动达人', 'description': '连续运动7天'},
          {'achievement_id': 5, 'language_code': 'en', 'name': 'Exercise Expert', 'description': 'Exercise for 7 consecutive days'},
          
          // Calorie Crusher
          {'achievement_id': 6, 'language_code': 'zh', 'name': '卡路里杀手', 'description': '累计消耗1000卡路里'},
          {'achievement_id': 6, 'language_code': 'en', 'name': 'Calorie Crusher', 'description': 'Burn a total of 1000 calories'},
          
          // Time Master
          {'achievement_id': 7, 'language_code': 'zh', 'name': '时间管理大师', 'description': '累计运动时间达到10小时'},
          {'achievement_id': 7, 'language_code': 'en', 'name': 'Time Master', 'description': 'Accumulate 10 hours of exercise time'},
        ];
        
        for (final data in achievementI18nData) {
          await db.insert('achievements_i18n', data);
        }
        
        debugPrint('Achievement i18n data insertion completed, inserted ${achievementI18nData.length} records');
      } else {
        debugPrint('Achievement i18n data already exists, skipping insertion');
      }
    } catch (e) {
      debugPrint('Error occurred while inserting achievement i18n data: $e');
    }
  }

  // Achievement related methods
  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    final db = await database;
    return await db.query(
      'achievements',
      where: 'deleted = ?',
      whereArgs: [0],
      orderBy: 'achievement_id ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getUserAchievements(int userId, [String languageCode = 'zh']) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        a.achievement_id,
        a.icon,
        a.type,
        a.target_value,
        a.created_at,
        COALESCE(ai.name, a.name) as name,
        COALESCE(ai.description, a.description) as description,
        ua.is_achieved, 
        ua.current_progress, 
        ua.achieved_at
      FROM achievements a
      LEFT JOIN achievements_i18n ai ON a.achievement_id = ai.achievement_id AND ai.language_code = ?
      LEFT JOIN user_achievements ua ON a.achievement_id = ua.achievement_id AND ua.user_id = ? AND ua.deleted = 0
      WHERE a.deleted = 0
      ORDER BY a.achievement_id ASC
    ''', [languageCode, userId]);
  }

  Future<void> updateUserAchievement(int userId, int achievementId, int progress, bool isAchieved) async {
    final db = await database;
    
    final existing = await db.query(
      'user_achievements',
      where: 'user_id = ? AND achievement_id = ? AND deleted = 0',
      whereArgs: [userId, achievementId],
    );
    
    final data = <String, Object?>{
      'current_progress': progress,
      'is_achieved': isAchieved ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (isAchieved) {
      data['achieved_at'] = DateTime.now().toIso8601String();
    } else {
      data['achieved_at'] = null; // Explicitly set to null
    }
    
    if (existing.isEmpty) {
      // Create new record
      data['user_id'] = userId;
      data['achievement_id'] = achievementId;
      data['created_at'] = DateTime.now().toIso8601String();
      await db.insert('user_achievements', data);
    } else {
      // Update existing record
      await db.update(
        'user_achievements',
        data,
        where: 'user_id = ? AND achievement_id = ? AND deleted = 0',
        whereArgs: [userId, achievementId],
      );
    }
  }

  Future<bool> isFavorite(int userId, int tipId) async {
    final db = await database;
    final result = await db.query(
      'user_favorites',
      where: 'user_id = ? AND tip_id = ? AND deleted = 0',
      whereArgs: [userId, tipId],
    );
    return result.isNotEmpty;
  }

  Future<List<UserTip>> getUserFavorites(int userId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT ut.* FROM user_tips ut
      INNER JOIN user_favorites uf ON ut.tip_id = uf.tip_id
      WHERE uf.user_id = ? AND uf.deleted = 0 AND ut.deleted = 0
      ORDER BY uf.created_at DESC
    ''', [userId]);
    
    return result.map((map) => UserTip.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
