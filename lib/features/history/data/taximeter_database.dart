import 'package:sqflite/sqflite.dart';

/// Dùng chung một kết nối SQLite để bảo đảm migration v1→v2 không mất snapshot.
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
      final db = await openDatabase('$base/bot_taximeter.db',
        version: 2,
        onCreate: (database, _) async {
          await database.execute('CREATE TABLE trip_snapshots ('
            'id TEXT PRIMARY KEY, payload TEXT NOT NULL, updated_at INTEGER)');
          await _createCompleted(database);
        },
        onUpgrade: (database, oldVersion, _) async {
          if (oldVersion < 2) await _createCompleted(database);
        },
      );
      return _database = db;
    } catch (_) {
      _opening = null;
      rethrow;
    }
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
