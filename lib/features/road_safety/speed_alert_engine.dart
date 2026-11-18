/// Cảnh báo vượt ngưỡng do tài xế tự đặt, KHÔNG phải biển giới hạn pháp lý.
enum SpeedAlertStatus { disabled, noReliableGps, withinThreshold, exceeding }

class SpeedAlertReading {
  const SpeedAlertReading({
    required this.status, required this.thresholdKmh,
    this.speedKmh, this.newAlert = false,
  });

  final SpeedAlertStatus status;
  final int thresholdKmh;
  final double? speedKmh;
  final bool newAlert;

  bool get isOver => status == SpeedAlertStatus.exceeding;
}

/// Xử lý thuần Dart: từ chối GPS cũ/yếu, chống nhiễu và chống cảnh báo lặp.
class SpeedAlertEngine {
  SpeedAlertEngine({
    this.marginKmh = 5,
    this.minConsecutive = 3,
    this.clearConsecutive = 2,
    this.cooldown = const Duration(seconds: 30),
  });

  final int marginKmh;
  final int minConsecutive;
  final int clearConsecutive;
  final Duration cooldown;
  int _highSamples = 0;
  int _lowSamples = 0;
  bool _over = false;
  DateTime? _lastAlert;
  DateTime? _lastFixTime;

  void reset() {
    _highSamples = 0;
    _lowSamples = 0;
    _over = false;
    _lastAlert = null;
    _lastFixTime = null;
  }

  SpeedAlertReading evaluate({
    required bool enabled,
    required int thresholdKmh,
    required double? speedKmh,
    required double? accuracyMeters,
    required DateTime? fixTime,
    required DateTime now,
  }) {
    if (!enabled) {
      _resetSamples();
      return SpeedAlertReading(
          status: SpeedAlertStatus.disabled, thresholdKmh: thresholdKmh);
    }

    final age = fixTime == null ? null : now.difference(fixTime);
    final reliable = thresholdKmh >= 30 && thresholdKmh <= 130 &&
        speedKmh != null && speedKmh.isFinite &&
        speedKmh >= 0 && speedKmh <= 200 &&
        accuracyMeters != null && accuracyMeters.isFinite &&
        accuracyMeters >= 0 && accuracyMeters <= 15 &&
        age != null && !age.isNegative &&
        age <= const Duration(seconds: 5) &&
        (_lastFixTime == null || fixTime!.isAfter(_lastFixTime!));

    if (!reliable) {
      _resetSamples();
      return SpeedAlertReading(
          status: SpeedAlertStatus.noReliableGps, thresholdKmh: thresholdKmh);
    }
    // Nếu luồng GPS ngắt >4 giây, không nối các điểm cũ thành chuỗi vượt.
    if (_lastFixTime != null &&
        fixTime!.difference(_lastFixTime!) > const Duration(seconds: 4)) {
      _resetSamples();
    }
    _lastFixTime = fixTime;
    // Tốc độ cần vượt ngưỡng ít nhất 5km/h trong 3 mẫu GPS liên tiếp.
    if (speedKmh > thresholdKmh + marginKmh) {
      _highSamples++;
      _lowSamples = 0;
      if (_highSamples >= minConsecutive) _over = true;
    } else if (speedKmh <= thresholdKmh + 1) {
      _lowSamples++;
      _highSamples = 0;
      if (_lowSamples >= clearConsecutive) _over = false;
    } else {
      _highSamples = 0;
      _lowSamples = 0;
    }

    final shouldAlert = _over && (_lastAlert == null ||
        now.difference(_lastAlert!) >= cooldown);
    if (shouldAlert) _lastAlert = now;
    return SpeedAlertReading(
      status: _over ? SpeedAlertStatus.exceeding
          : SpeedAlertStatus.withinThreshold,
      thresholdKmh: thresholdKmh,
      speedKmh: speedKmh,
      newAlert: shouldAlert,
    );
  }

  void _resetSamples() {
    _highSamples = 0;
    _lowSamples = 0;
    _over = false;
    _lastFixTime = null;
  }
}
