import 'package:sqflite/sqflite.dart';

import '../../map_tracking/data/gps_tracker.dart';
import 'completed_trip.dart';
import 'taximeter_database.dart';

/// Lưu duy nhất mỗi chuyến theo ID ổn định, tránh cộng doanh thu hai lần.
abstract class CompletedTripStore {
  Future<void> save(CompletedTrip trip);
  Future<List<CompletedTrip>> all();
}

class MemoryCompletedTripStore implements CompletedTripStore {
  final Map<String, CompletedTrip> records = {};
  @override
  Future<void> save(CompletedTrip trip) async {
    records.putIfAbsent(trip.id, () => trip);
  }
  @override
  Future<List<CompletedTrip>> all() async {
    final trips = records.values.toList();
    trips.sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    return trips;
  }
}

class SqliteCompletedTripStore implements CompletedTripStore {
  @override
  Future<void> save(CompletedTrip trip) async {
    final db = await TaximeterDatabase.instance;
    await db.insert('completed_trips', trip.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<List<CompletedTrip>> all() async {
    final db = await TaximeterDatabase.instance;
    final rows = await db.query('completed_trips',
        orderBy: 'finished_at DESC');
    return rows.map(CompletedTrip.fromMap).toList(growable: false);
  }
}

/// Test/CI mặc định không gọi SQLite native. Không cần quyền hay API mới.
class CompletedTripStores {
  CompletedTripStores._();
  static final CompletedTripStore instance = GpsTracker.useMock
      ? MemoryCompletedTripStore() : SqliteCompletedTripStore();
}
