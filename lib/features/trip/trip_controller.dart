import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../fare_meter/fare_calculator.dart';
import '../map_tracking/data/gps_tracker.dart';

enum TripState { idle, pickingUp, inTrip, waiting, completed }

abstract class TripStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> value);
  Future<void> clear();
}

/// Test/CI không mở SQLite của thiết bị.
class MemoryTripStore implements TripStore {
  Map<String, dynamic>? current;
  @override
  Future<Map<String, dynamic>?> read() async =>
      current == null ? null : Map<String, dynamic>.from(current!);
  @override
  Future<void> write(Map<String, dynamic> value) async {
    current = Map<String, dynamic>.from(value);
  }
  @override
  Future<void> clear() async { current = null; }
}

/// Snapshot bền vững trên máy; bảng lịch sử cuốc hoàn chỉnh thuộc Bước 13.
class SqliteTripStore implements TripStore {
  Database? _database;
  Future<Database> get _db async {
    if (_database != null) return _database!;
    final base = await getDatabasesPath();
    final db = await openDatabase('$base/bot_taximeter.db',
      version: 1,
      onCreate: (database, _) async {
        await database.execute('CREATE TABLE trip_snapshots ('
            'id TEXT PRIMARY KEY, payload TEXT NOT NULL, updated_at INTEGER)');
      },
    );
    return _database = db;
  }
  @override
  Future<Map<String, dynamic>?> read() async {
    final rows = await (await _db).query('trip_snapshots',
        where: 'id = ?', whereArgs: <Object>['active'], limit: 1);
    if (rows.isEmpty) return null;
    final parsed = jsonDecode(rows.first['payload'] as String);
    return parsed is Map<String, dynamic> ? parsed : null;
  }
  @override
  Future<void> write(Map<String, dynamic> value) async {
    await (await _db).insert('trip_snapshots',
      <String, Object?>{
        'id': 'active', 'payload': jsonEncode(value),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  @override
  Future<void> clear() async {
    await (await _db).delete('trip_snapshots',
        where: 'id = ?', whereArgs: <Object>['active']);
  }
}

/// Mọi chuyển trạng thái đi qua controller, không nằm ở widget.
class TripController extends ChangeNotifier {
  TripController({
    required TripStore store, DateTime Function()? clock,
    double Function()? distanceSource, double Function()? speedSource,
    this.runTimer = true,
  }) : _store = store, _clock = clock ?? DateTime.now,
       _distanceSource = distanceSource ??
           (() => GpsTracker.instance.distanceMeters),
       _speedSource = speedSource ??
           (() => GpsTracker.instance.fix?.speedKmh ?? -1);

  static final TripController instance = TripController(
    store: GpsTracker.useMock ? MemoryTripStore() : SqliteTripStore());

  final TripStore _store;
  final DateTime Function() _clock;
  final double Function() _distanceSource, _speedSource;
  final bool runTimer;
  TripState state = TripState.idle;
  FareConfig config = const FareConfig();
  bool autoWaiting = false;
  int elapsedSeconds = 0, waitingSeconds = 0, tollFee = 0;
  double distanceMeters = 0;
  DateTime? startedAt;
  Map<String, dynamic>? pending;
  DateTime? _lastTick;
  double? _gpsBaseline;
  int _lastSavedSeconds = -1, _slowSeconds = 0;
  bool _manualPause = false;
  Timer? _ticker;
  Future<void> _writes = Future<void>.value();

  bool get isActive => state == TripState.inTrip ||
      state == TripState.waiting || state == TripState.pickingUp;
  FareBreakdown get fare => FareCalculator(config).calculate(
    distanceKm: distanceMeters / 1000,
    waitingSeconds: waitingSeconds, tollFee: tollFee,
  );

  Future<void> readSettings() async {
    try {
      final p = await SharedPreferences.getInstance();
      config = FareConfig.fromJson(<String, dynamic>{
        'opening': p.getInt('fare_opening') ?? 30000,
        'tier1': p.getInt('fare_tier1') ?? 13000,
        'tier2': p.getInt('fare_tier2') ?? 11500,
        'tier3': p.getInt('fare_tier3') ?? 10000,
        'waitHour': p.getInt('fare_wait_hour') ?? 30000,
        'freeWait': p.getInt('fare_free_wait') ?? 5,
      });
      autoWaiting = p.getBool('fare_auto_wait') ?? false;
    } catch (_) {
      config = const FareConfig();
      autoWaiting = false;
    }
  }

  Future<bool> loadPending() async {
    try {
      final data = await _store.read();
      if (data == null || data['version'] != 1 ||
          (data['state'] != 'inTrip' && data['state'] != 'waiting')) {
        pending = null;
        return false;
      }
      pending = data;
      return true;
    } catch (_) {
      pending = null;
      return false;
    }
  }

  Future<void> begin() async {
    if (isActive) return;
    await _writes;
    await _store.clear();
    await readSettings();
    state = TripState.inTrip;
    elapsedSeconds = 0; waitingSeconds = 0; tollFee = 0;
    distanceMeters = 0; _gpsBaseline = null;
    _manualPause = false;
    _slowSeconds = 0; _lastSavedSeconds = -1;
    startedAt = _clock(); _lastTick = startedAt;
    pending = null;
    _startTicker(); _persist();
    notifyListeners();
  }

  Future<void> restore() async {
    final data = pending;
    if (data == null) return;
    final restored = TripState.values.firstWhere(
      (e) => e.name == data['state'],
      orElse: () => TripState.idle,
    );
    if (restored != TripState.inTrip && restored != TripState.waiting) return;
    state = restored;
    elapsedSeconds = (data['elapsed'] as num).toInt();
    waitingSeconds = (data['waiting'] as num).toInt();
    tollFee = (data['toll'] as num).toInt();
    distanceMeters = (data['meters'] as num).toDouble();
    config = FareConfig.fromJson(
        Map<String, dynamic>.from(data['config'] as Map));
    autoWaiting = data['autoWaiting'] == true;
    _manualPause = data['manualPause'] == true;
    startedAt = DateTime.fromMillisecondsSinceEpoch(
        (data['started'] as num).toInt());
    _gpsBaseline = null;
    _slowSeconds = 0; _lastSavedSeconds = elapsedSeconds;
    _lastTick = _clock(); pending = null;
    _startTicker(); notifyListeners();
  }

  Future<void> discardPending() async {
    pending = null;
    await _writes;
    await _store.clear();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (runTimer) _ticker = Timer.periodic(
        const Duration(seconds: 1), (_) => tick(intervalSeconds: 1));
  }

  /// Ghi chênh lệch GPS hợp lệ, không nối khoảng cách khi app đã đóng.
  void _updateDistance() {
    final meters = _distanceSource();
    if (!meters.isFinite || meters < 0) return;
    final previous = _gpsBaseline;
    _gpsBaseline = meters;
    if (previous != null && meters >= previous &&
        state == TripState.inTrip) {
      distanceMeters += meters - previous;
    }
  }

  void tick({int? intervalSeconds}) {
    if (!isActive) return;
    final now = _clock();
    final delta = intervalSeconds ?? (_lastTick == null ? 0 :
        now.difference(_lastTick!).inSeconds.clamp(0, 30).toInt());
    if (delta <= 0) return;
    _lastTick = now;
    _updateDistance();
    elapsedSeconds += delta;
    if (state == TripState.waiting) waitingSeconds += delta;
    if (autoWaiting && !_manualPause && _speedSource() >= 0) {
      _slowSeconds = _speedSource() < 3 ? _slowSeconds + delta : 0;
      if (state == TripState.inTrip && _slowSeconds >= 10) {
        state = TripState.waiting;
      } else if (state == TripState.waiting &&
          _speedSource() >= 3) {
        state = TripState.inTrip;
      }
    }
    if (elapsedSeconds - _lastSavedSeconds >= 3) _persist();
    notifyListeners();
  }

  void pause() {
    if (state != TripState.inTrip) return;
    tick(); state = TripState.waiting; _manualPause = true;
    _slowSeconds = 0;
    _persist(); notifyListeners();
  }
  void resume() {
    if (state != TripState.waiting) return;
    tick(); state = TripState.inTrip; _manualPause = false;
    _slowSeconds = 0;
    _persist(); notifyListeners();
  }
  void addToll(int amount) {
    if (!isActive || amount < 0) throw StateError('BOT không hợp lệ');
    tollFee += amount; _persist(); notifyListeners();
  }

  Map<String, dynamic> _snapshot() => <String, dynamic>{
    'version': 1, 'state': state.name,
    'started': startedAt?.millisecondsSinceEpoch,
    'elapsed': elapsedSeconds, 'waiting': waitingSeconds,
    'meters': distanceMeters, 'toll': tollFee,
    'config': config.toJson(), 'autoWaiting': autoWaiting,
    'manualPause': _manualPause,
  };

  void _persist() {
    _lastSavedSeconds = elapsedSeconds;
    final snapshot = _snapshot();
    _writes = _writes.then((_) => _store.write(snapshot))
        .catchError((Object _) {});
  }
  Future<void> flush() => _writes;

  Future<void> complete() async {
    if (!isActive) return;
    tick(); state = TripState.completed; _ticker?.cancel();
    await _writes; await _store.clear();
    notifyListeners();
  }

  /// Chỉ dùng để dọn tài nguyên khi không có chuyến đang chạy.
  @override
  void dispose() { _ticker?.cancel(); super.dispose(); }
}
