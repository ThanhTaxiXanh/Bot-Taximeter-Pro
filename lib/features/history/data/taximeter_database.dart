import 'package:sqflite/sqflite.dart';

/// Một kết nối SQLite; migration v1→v2→v3 giữ snapshot và chuyến cũ.
class TaximeterDatabase {
  TaximeterDatabase._();
  static Database? _database;
  static Future<Database>? _opening;

  static Future<Database> get instance async {
    if (_database != null) return _database!;
    return _opening ??= _open();
  }

  static Future<Database> _open() async {
    try {
      final base = await getDatabasesPath();
      final db = await openAtPath('$base/bot_taximeter.db');
      return _database = db;
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  /// Mở schema hiện hành tại đường dẫn độc lập để test nâng cấp dữ liệu cũ.
  static Future<Database> openAtPath(String path) => openDatabase(path,
        version: 3,
        onCreate: (database, _) async {
          await database.execute('CREATE TABLE trip_snapshots ('
            'id TEXT PRIMARY KEY, payload TEXT NOT NULL, updated_at INTEGER)');
          await _createCompleted(database);
          await _createBanks(database);
        },
        onUpgrade: (database, oldVersion, _) async {
          if (oldVersion < 2) await _createCompleted(database);
          if (oldVersion < 3) await _createBanks(database);
        },
      );

  static Future<void> _createBanks(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS banks ('
      'bin TEXT PRIMARY KEY, short_name TEXT NOT NULL,'
      'full_name TEXT NOT NULL, bank_code TEXT NOT NULL)');
  }

  static Future<void> _createCompleted(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS completed_trips ('
      'id TEXT PRIMARY KEY,'
      'started_at INTEGER NOT NULL, finished_at INTEGER NOT NULL,'
      'fare_vnd INTEGER NOT NULL, distance_meters REAL NOT NULL,'
      'elapsed_seconds INTEGER NOT NULL, waiting_seconds INTEGER NOT NULL,'
      'wait_fee_vnd INTEGER NOT NULL, toll_vnd INTEGER NOT NULL)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_completed_finished '
      'ON completed_trips(finished_at DESC)');
  }
}
