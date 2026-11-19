import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

import 'package:bot_taximeter_pro/features/history/data/taximeter_database.dart';

/// Test trên SQLite native Android với file riêng, không chạm DB thật.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final oldVersion in <int>[1, 2]) {
    testWidgets('Nâng SQLite v$oldVersion lên v3 không mất dữ liệu',
        (tester) async {
      final path = '${await getDatabasesPath()}/acceptance_v$oldVersion.db';
      await deleteDatabase(path);
      Database? previous, upgraded;
      try {
        previous = await openDatabase(path, version: oldVersion,
          onCreate: (db, _) async {
            await db.execute('CREATE TABLE trip_snapshots ('
                'id TEXT PRIMARY KEY, payload TEXT NOT NULL,'
                'updated_at INTEGER)');
            if (oldVersion >= 2) {
              await db.execute('CREATE TABLE completed_trips ('
                  'id TEXT PRIMARY KEY, started_at INTEGER NOT NULL,'
                  'finished_at INTEGER NOT NULL, fare_vnd INTEGER NOT NULL,'
                  'distance_meters REAL NOT NULL,'
                  'elapsed_seconds INTEGER NOT NULL,'
                  'waiting_seconds INTEGER NOT NULL,'
                  'wait_fee_vnd INTEGER NOT NULL,'
                  'toll_vnd INTEGER NOT NULL)');
              await db.execute('CREATE INDEX idx_completed_finished '
                  'ON completed_trips(finished_at DESC)');
            }
          },
        );
        await previous.insert('trip_snapshots', <String, Object?>{
          'id': 'active',
          'payload': jsonEncode(<String, Object>{
            'version': 1, 'state': 'waiting', 'toll': 5000,
          }),
          'updated_at': 1763540000000,
        });
        if (oldVersion >= 2) {
          await previous.insert('completed_trips', <String, Object?>{
            'id': 'TTX-ACCEPTANCE',
            'started_at': 1763540000000,
            'finished_at': 1763541200000,
            'fare_vnd': 42000,
            'distance_meters': 2500.0,
            'elapsed_seconds': 1200,
            'waiting_seconds': 60,
            'wait_fee_vnd': 0,
            'toll_vnd': 5000,
          });
        }
        await previous.close();
        previous = null;

        // Gọi cùng hàm mở DB thật của ứng dụng, không sao chép migration.
        upgraded = await TaximeterDatabase.openAtPath(path);
        final version = await upgraded.rawQuery('PRAGMA user_version');
        expect(version.first['user_version'], 3);
        final snapshot = await upgraded.query('trip_snapshots',
            where: 'id = ?', whereArgs: <Object>['active']);
        expect(snapshot.length, 1);
        final data = jsonDecode(snapshot.single['payload'] as String) as Map;
        expect(data['state'], 'waiting');
        expect(data['toll'], 5000);

        final oldTrips = await upgraded.query('completed_trips');
        expect(oldTrips.length, oldVersion == 2 ? 1 : 0);
        if (oldVersion == 2) {
          expect(oldTrips.single['id'], 'TTX-ACCEPTANCE');
          expect(oldTrips.single['fare_vnd'], 42000);
        }
        await upgraded.insert('banks', <String, Object>{
          'bin': '970436', 'short_name': 'Vietcombank',
          'full_name': 'Ngân hàng Ngoại thương', 'bank_code': 'VCB',
        });
        final banks = await upgraded.query('banks');
        expect(banks.length, 1);
        expect(banks.single['bin'], '970436');
      } finally {
        await previous?.close();
        await upgraded?.close();
        await deleteDatabase(path);
      }
    });
  }

  testWidgets('Cài mới SQLite v3 có đủ ba bảng', (tester) async {
    final path = '${await getDatabasesPath()}/acceptance_fresh.db';
    await deleteDatabase(path);
    Database? database;
    try {
      database = await TaximeterDatabase.openAtPath(path);
      final tables = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = tables.map((row) => row['name']).toSet();
      expect(names, containsAll(<String>[
        'trip_snapshots', 'completed_trips', 'banks',
      ]));
    } finally {
      await database?.close();
      await deleteDatabase(path);
    }
  });
}
