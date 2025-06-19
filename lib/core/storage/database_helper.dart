import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static DatabaseHelper get instance => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'spb_secure.db');
      
      AppLogger.info('Initializing database at: $path');
      
      return await openDatabase(
        path,
        version: 3, // Increased version for QR code table
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    } catch (e) {
      AppLogger.error('Failed to initialize database', e);
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      AppLogger.info('Creating database tables...');
      
      // Settings table for local storage
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT UNIQUE NOT NULL,
          value TEXT,
          type TEXT NOT NULL DEFAULT 'string',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
        )
      ''');

      // Users table with username support
      await db.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE NOT NULL,
          email TEXT UNIQUE,
          name TEXT NOT NULL,
          avatar TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          synced_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          last_sync_status TEXT DEFAULT 'success',
          sync_error TEXT,
          is_dirty BOOLEAN NOT NULL DEFAULT 0,
          local_updated_at INTEGER
        )
      ''');

      // Data entries table for main application data
      await db.execute('''
        CREATE TABLE data_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          remote_id TEXT UNIQUE,
          name TEXT NOT NULL,
          email TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'active',
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          synced_at INTEGER,
          is_dirty INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Activity logs table
      await db.execute('''
        CREATE TABLE activity_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          description TEXT NOT NULL,
          user_id TEXT,
          username TEXT,
          metadata TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
          FOREIGN KEY (username) REFERENCES users (username) ON DELETE SET NULL
        )
      ''');

      // Sync queue table for offline operations
      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          operation TEXT NOT NULL,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          data TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
          retry_count INTEGER NOT NULL DEFAULT 0,
          last_error TEXT,
          priority INTEGER NOT NULL DEFAULT 5,
          status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');
      
      // QR codes table
      await db.execute('''
        CREATE TABLE qr_codes (
          id TEXT PRIMARY KEY,
          driver TEXT NOT NULL,
          kd_vendor TEXT NOT NULL,
          content TEXT NOT NULL,
          size INTEGER NOT NULL,
          error_correction_level TEXT NOT NULL,
          foreground_color TEXT NOT NULL,
          background_color TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // Create indexes for better performance
      await db.execute('CREATE INDEX idx_settings_key ON settings (key)');
      await db.execute('CREATE INDEX idx_users_username ON users (username)');
      await db.execute('CREATE INDEX idx_users_email ON users (email)');
      await db.execute('CREATE INDEX idx_users_is_dirty ON users (is_dirty)');
      await db.execute('CREATE INDEX idx_users_synced_at ON users (synced_at)');
      await db.execute('CREATE INDEX idx_data_entries_status ON data_entries (status)');
      await db.execute('CREATE INDEX idx_data_entries_synced ON data_entries (synced_at)');
      await db.execute('CREATE INDEX idx_activity_logs_type ON activity_logs (type)');
      await db.execute('CREATE INDEX idx_activity_logs_username ON activity_logs (username)');
      await db.execute('CREATE INDEX idx_activity_logs_created ON activity_logs (created_at)');
      await db.execute('CREATE INDEX idx_sync_queue_operation ON sync_queue (operation)');
      await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue (status)');
      await db.execute('CREATE INDEX idx_sync_queue_priority ON sync_queue (priority)');
      await db.execute('CREATE INDEX idx_qr_codes_driver ON qr_codes (driver)');
      await db.execute('CREATE INDEX idx_qr_codes_created_at ON qr_codes (created_at)');

      AppLogger.info('Database tables created successfully');
    } catch (e) {
      AppLogger.error('Failed to create database tables', e);
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('Upgrading database from version $oldVersion to $newVersion');
    
    if (oldVersion < 2) {
      // Migration to add username support
      await _migrateToUsernameAuth(db);
    }
    
    if (oldVersion < 3) {
      // Migration to add QR codes table
      await _migrateToAddQrCodesTable(db);
    }
    
    if (oldVersion < 4) {
      // Migration to add user profile sync fields
      await _migrateToAddUserSyncFields(db);
    }
  }

  Future<void> _migrateToUsernameAuth(Database db) async {
    try {
      AppLogger.info('Migrating to username-based authentication...');
      
      // Add username column to users table
      await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
      
      // Add username column to activity_logs
      await db.execute('ALTER TABLE activity_logs ADD COLUMN username TEXT');
      
      // Create new indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_users_username ON users (username)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_logs_username ON activity_logs (username)');
      
      // Generate usernames for existing users (email prefix)
      final existingUsers = await db.query('users');
      for (final user in existingUsers) {
        if (user['username'] == null && user['email'] != null) {
          final email = user['email'] as String;
          final username = email.split('@')[0];
          await db.update(
            'users',
            {'username': username},
            where: 'id = ?',
            whereArgs: [user['id']],
          );
        }
      }
      
      // Make username unique and not null
      await db.execute('CREATE UNIQUE INDEX idx_users_username_unique ON users (username)');
      
      AppLogger.info('Username authentication migration completed');
    } catch (e) {
      AppLogger.error('Failed to migrate to username authentication', e);
      rethrow;
    }
  }
  
  Future<void> _migrateToAddQrCodesTable(Database db) async {
    try {
      AppLogger.info('Migrating to add QR codes table...');
      
      // Check if qr_codes table already exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='qr_codes'"
      );
      
      if (tables.isEmpty) {
        // Create QR codes table
        await db.execute('''
          CREATE TABLE qr_codes (
            id TEXT PRIMARY KEY,
            driver TEXT NOT NULL,
            kd_vendor TEXT NOT NULL,
            content TEXT NOT NULL,
            size INTEGER NOT NULL,
            error_correction_level TEXT NOT NULL,
            foreground_color TEXT NOT NULL,
            background_color TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        
        // Create indexes
        await db.execute('CREATE INDEX idx_qr_codes_driver ON qr_codes (driver)');
        await db.execute('CREATE INDEX idx_qr_codes_created_at ON qr_codes (created_at)');
        
        AppLogger.info('QR codes table created successfully');
      } else {
        AppLogger.info('QR codes table already exists, skipping migration');
      }
    } catch (e) {
      AppLogger.error('Failed to migrate to add QR codes table', e);
      rethrow;
    }
  }
  
  Future<void> _migrateToAddUserSyncFields(Database db) async {
    try {
      AppLogger.info('Migrating to add user profile sync fields...');
      
      // Check if the columns already exist
      final userTableInfo = await db.rawQuery('PRAGMA table_info(users)');
      final columnNames = userTableInfo.map((col) => col['name'] as String).toList();
      
      // Add sync status column if it doesn't exist
      if (!columnNames.contains('last_sync_status')) {
        await db.execute('ALTER TABLE users ADD COLUMN last_sync_status TEXT DEFAULT "success"');
      }
      
      // Add sync error column if it doesn't exist
      if (!columnNames.contains('sync_error')) {
        await db.execute('ALTER TABLE users ADD COLUMN sync_error TEXT');
      }
      
      // Add is_dirty column if it doesn't exist
      if (!columnNames.contains('is_dirty')) {
        await db.execute('ALTER TABLE users ADD COLUMN is_dirty BOOLEAN NOT NULL DEFAULT 0');
      }
      
      // Add local_updated_at column if it doesn't exist
      if (!columnNames.contains('local_updated_at')) {
        await db.execute('ALTER TABLE users ADD COLUMN local_updated_at INTEGER');
      }
      
      // Create index for is_dirty if it doesn't exist
      final indexes = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='users'");
      final indexNames = indexes.map((idx) => idx['name'] as String).toList();
      
      if (!indexNames.contains('idx_users_is_dirty')) {
        await db.execute('CREATE INDEX idx_users_is_dirty ON users (is_dirty)');
      }
      
      AppLogger.info('User profile sync fields migration completed');
    } catch (e) {
      AppLogger.error('Failed to migrate user profile sync fields', e);
      rethrow;
    }
  }

  // Generic CRUD operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    try {
      // Add timestamps if not provided
      if (!data.containsKey('created_at')) {
        data['created_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
      if (!data.containsKey('updated_at')) {
        data['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
      
      return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      AppLogger.error('Failed to insert into $table', e);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    try {
      return await db.query(
        table,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      AppLogger.error('Failed to query $table', e);
      rethrow;
    }
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    try {
      // Add updated_at timestamp if not provided
      if (!data.containsKey('updated_at')) {
        data['updated_at'] = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
      
      return await db.update(table, data, where: where, whereArgs: whereArgs);
    } catch (e) {
      AppLogger.error('Failed to update $table', e);
      rethrow;
    }
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    try {
      return await db.delete(table, where: where, whereArgs: whereArgs);
    } catch (e) {
      AppLogger.error('Failed to delete from $table', e);
      rethrow;
    }
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('settings');
      await txn.delete('users');
      await txn.delete('data_entries');
      await txn.delete('activity_logs');
      await txn.delete('sync_queue');
      await txn.delete('qr_codes');
    });
    AppLogger.info('All database data cleared');
  }
}