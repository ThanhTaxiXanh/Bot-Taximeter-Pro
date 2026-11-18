import 'dart:math' as math;

/// Điểm GPS thuần Dart để kiểm thử không cần plugin hoặc thiết bị.
class GpsPoint {
  const GpsPoint({
    required this.latitude, required this.longitude,
    required this.accuracyMeters, required this.speedMetersPerSecond,
    required this.headingDegrees, required this.timestamp,
  });
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedMetersPerSecond;
  final double headingDegrees;
  final DateTime timestamp;
}

class GpsFix {
  const GpsFix({
    required this.point, required this.speedKmh,
    required this.totalMeters,
  });
  final GpsPoint point;
  final double speedKmh;
  final double totalMeters;
}

/// Haversine chuẩn WGS84 gần đúng, không gọi dịch vụ bản đồ.
double haversineMeters(
  double latitude1, double longitude1,
  double latitude2, double longitude2,
) {
  const radius = 6371000.0;
  const toRadians = math.pi / 180;
  final dLat = (latitude2 - latitude1) * toRadians;
  final dLon = (longitude2 - longitude1) * toRadians;
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(latitude1 * toRadians) *
          math.cos(latitude2 * toRadians) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * radius * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

/// Lọc accuracy >25m, bước nhảy >200km/h, bước nhỏ <5m hoặc <3km/h.
/// Không có độ chính xác pháp lý cho việc đo cước bằng GPS điện thoại.
class GpsFilter {
  GpsPoint? _last;
  GpsPoint? _distanceAnchor;
  GpsFix? _fix;
  double _distance = 0;
  double _smoothSpeed = 0;

  GpsFix? get lastFix => _fix;
  double get totalMeters => _distance;

  void reset() {
    _last = null;
    _distanceAnchor = null;
    _fix = null;
    _distance = 0;
    _smoothSpeed = 0;
  }

  GpsFix? add(GpsPoint point, {bool recordDistance = true}) {
    if (!_valid(point)) return null;
    final previous = _last;
    var observedKmh = point.speedMetersPerSecond.isFinite &&
            point.speedMetersPerSecond >= 0
        ? point.speedMetersPerSecond * 3.6 : 0.0;
    if (observedKmh > 200) return null;
    if (previous != null) {
      final elapsed = point.timestamp.difference(previous.timestamp)
          .inMilliseconds / 1000.0;
      if (elapsed <= 0) return null;
      final meters = haversineMeters(
        previous.latitude, previous.longitude,
        point.latitude, point.longitude,
      );
      final jumpKmh = meters / elapsed * 3.6;
      if (jumpKmh > 200) return null;
      if (point.speedMetersPerSecond < 0) observedKmh = jumpKmh;
    }
    _smoothSpeed = previous == null
        ? observedKmh : (_smoothSpeed * .7 + observedKmh * .3);
    if (recordDistance && _distanceAnchor != null) {
      final segment = haversineMeters(
        _distanceAnchor!.latitude, _distanceAnchor!.longitude,
        point.latitude, point.longitude,
      );
      if (segment >= 5 && _smoothSpeed >= 3) {
        _distance += segment;
        _distanceAnchor = point;
      } else if (_smoothSpeed < 3) {
        // Không tích lũy bước nhảy GPS khi đứng yên.
        _distanceAnchor = point;
      }
    } else {
      _distanceAnchor = point;
    }
    _last = point;
    _fix = GpsFix(
      point: point,
      speedKmh: _smoothSpeed.clamp(0.0, 200.0).toDouble(),
      totalMeters: _distance,
    );
    return _fix;
  }

  bool _valid(GpsPoint p) =>
      p.latitude.isFinite && p.longitude.isFinite &&
      p.latitude.abs() <= 90 && p.longitude.abs() <= 180 &&
      p.accuracyMeters.isFinite &&
      p.accuracyMeters >= 0 && p.accuracyMeters <= 25 &&
      p.headingDegrees.isFinite &&
      p.speedMetersPerSecond.isFinite &&
      !p.timestamp.isAfter(DateTime.now().add(const Duration(seconds: 30)));
}
