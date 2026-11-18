import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/road_safety/speed_alert_engine.dart';

void main() {
  SpeedAlertReading read(SpeedAlertEngine engine, int seconds, {
    double speed = 70, double accuracy = 5,
    bool enabled = true, int threshold = 60,
    int? gpsAgeSeconds,
  }) {
    final now = DateTime.utc(2026, 11, 18, 10).add(Duration(seconds: seconds));
    final fix = now.subtract(Duration(seconds: gpsAgeSeconds ?? 0));
    return engine.evaluate(enabled: enabled, thresholdKmh: threshold,
      speedKmh: speed, accuracyMeters: accuracy, fixTime: fix, now: now);
  }

  test('Mặc định tắt, không cảnh báo từ GPS hoặc giới hạn mẫu', () {
    final engine = SpeedAlertEngine();
    final result = read(engine, 0, enabled: false);
    expect(result.status, SpeedAlertStatus.disabled);
    expect(result.newAlert, isFalse);
  });

  test('Cần 3 mẫu GPS tin cậy vượt ngưỡng ít nhất 5km/h', () {
    final engine = SpeedAlertEngine();
    expect(read(engine, 0, speed: 66).isOver, isFalse);
    expect(read(engine, 1, speed: 66).isOver, isFalse);
    final third = read(engine, 2, speed: 66);
    expect(third.status, SpeedAlertStatus.exceeding);
    expect(third.newAlert, isTrue);
    expect(read(engine, 3, speed: 67).newAlert, isFalse);
    expect(read(engine, 4, speed: 60).isOver, isTrue);
    expect(read(engine, 5, speed: 60).isOver, isFalse);
  });

  test('Không báo khi chỉ có một đỉnh tốc độ hoặc tốc độ gần ngưỡng', () {
    final engine = SpeedAlertEngine();
    read(engine, 0, speed: 69);
    read(engine, 1, speed: 62);
    expect(read(engine, 2, speed: 69).isOver, isFalse);
    expect(read(engine, 3, speed: 65).isOver, isFalse);
    expect(read(engine, 4, speed: 60).isOver, isFalse);
  });

  test('GPS cũ/yếu, thời gian lùi hoặc cùng timestamp không hợp lệ', () {
    final engine = SpeedAlertEngine();
    expect(read(engine, 0, accuracy: 25).status,
        SpeedAlertStatus.noReliableGps);
    expect(read(engine, 2, gpsAgeSeconds: 7).status,
        SpeedAlertStatus.noReliableGps);
    expect(read(engine, 5, gpsAgeSeconds: -1).status,
        SpeedAlertStatus.noReliableGps);
    read(engine, 10);
    expect(read(engine, 10).status, SpeedAlertStatus.noReliableGps);
    expect(read(engine, 11).isOver, isFalse);
  });

  test('Không báo lặp trong 30 giây, không dùng ngưỡng quá cao', () {
    final engine = SpeedAlertEngine();
    read(engine, 0);
    read(engine, 1);
    expect(read(engine, 2).newAlert, isTrue);
    for (var second = 3; second < 32; second++) {
      expect(read(engine, second).newAlert, isFalse);
    }
    expect(read(engine, 32).newAlert, isTrue);
    expect(read(engine, 33, threshold: 140).status,
        SpeedAlertStatus.noReliableGps);
  });

  test('GPS ngắt quá 4 giây phải đếm lại chuỗi vượt ngưỡng', () {
    final engine = SpeedAlertEngine();
    read(engine, 0, speed: 80);
    read(engine, 1, speed: 80);
    expect(read(engine, 12, speed: 80).isOver, isFalse);
    expect(read(engine, 13, speed: 80).isOver, isFalse);
    expect(read(engine, 14, speed: 80).isOver, isTrue);
  });

  test('Reset không mang trạng thái vượt ngưỡng sang chuyến khác', () {
    final engine = SpeedAlertEngine();
    read(engine, 0);
    read(engine, 1);
    expect(read(engine, 2).isOver, isTrue);
    engine.reset();
    expect(read(engine, 3).isOver, isFalse);
  });
}
