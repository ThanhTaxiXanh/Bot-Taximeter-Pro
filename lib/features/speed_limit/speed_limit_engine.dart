import 'speed_rules.dart';

enum SpeedLimitSource { manual, posted, rule, ruleGuess, unknown }

enum OverspeedBand {
  unavailable, none, belowFive, fiveToUnderTen,
  tenToTwenty, overTwentyToThirtyFive, overThirtyFive,
}

/// postedConfirmed chỉ đúng sau khi đối chiếu biển thực tế còn hiệu lực.
/// Nếu chỉ lấy maxspeed từ OSM: postedConfirmed=false, KHÔNG bật cảnh báo.
class RoadContext {
  const RoadContext({
    this.vehicleClass = VehicleClass.lightPassengerOrTruck,
    this.areaType = AreaType.unknown,
    this.carriageway = Carriageway.unknown,
    this.manualLimitKmh,
    this.postedLimitKmh,
    this.postedMinKmh,
    this.postedConfirmed = false,
    this.areaInferred = false,
  });
  final VehicleClass vehicleClass;
  final AreaType areaType;
  final Carriageway carriageway;
  final int? manualLimitKmh, postedLimitKmh, postedMinKmh;
  final bool postedConfirmed, areaInferred;
}

class SpeedLimitResult {
  const SpeedLimitResult({
    required this.limitKmh, required this.minKmh,
    required this.source, required this.ruleRef, required this.canAlert,
  });
  final int? limitKmh, minKmh;
  final SpeedLimitSource source;
  final String ruleRef;
  /// Chưa bao gồm kiểm tra GPS 3 giây / giới hạn âm báo 15 giây (Bước 18).
  final bool canAlert;
  bool get isEstimate => source == SpeedLimitSource.ruleGuess ||
      (source == SpeedLimitSource.posted && !canAlert);
  String get displayLabel => limitKmh == null ? '--' :
      (isEstimate ? '~' : '') + limitKmh.toString();
}

class SpeedLimitEngine {
  const SpeedLimitEngine();
  static bool _valid(int? value) =>
      value != null && value >= 5 && value <= 120;

  int? _knownMotorwayMin(RoadContext road, int? max) {
    final min = road.postedMinKmh;
    if (road.areaType != AreaType.motorway || !road.postedConfirmed ||
        !_valid(min) || max == null || min! >= max) return null;
    return min;
  }

  SpeedLimitResult resolve(RoadContext road) {
    final manual = road.manualLimitKmh;
    if (_valid(manual)) {
      return SpeedLimitResult(
        limitKmh: manual, minKmh: _knownMotorwayMin(road, manual),
        source: SpeedLimitSource.manual,
        ruleRef: 'Tài xế nhập, cần đối chiếu biển hiệu lực',
        canAlert: true,
      );
    }
    final posted = road.postedLimitKmh;
    if (_valid(posted)) {
      return SpeedLimitResult(
        limitKmh: posted, minKmh: _knownMotorwayMin(road, posted),
        source: SpeedLimitSource.posted,
        ruleRef: road.postedConfirmed ? LegalBasis.roadSigns :
            'OSM/biển chưa được xác minh tại hiện trường',
        canAlert: road.postedConfirmed,
      );
    }
    // 120/60 chỉ là khung chung cao tốc: thiếu biển => không xác định.
    if (road.areaType == AreaType.motorway) return _unknown();
    final rule = SpeedRules.find(
        road.vehicleClass, road.areaType, road.carriageway);
    if (rule == null) return _unknown();
    return SpeedLimitResult(
      limitKmh: rule.limitKmh, minKmh: null,
      source: road.areaInferred
          ? SpeedLimitSource.ruleGuess : SpeedLimitSource.rule,
      ruleRef: rule.legalBasis + ', ' + rule.articleRef +
          ', hiệu lực ' + rule.effectiveFrom,
      canAlert: !road.areaInferred,
    );
  }

  SpeedLimitResult _unknown() => const SpeedLimitResult(
    limitKmh: null, minKmh: null, source: SpeedLimitSource.unknown,
    ruleRef: 'Chưa đủ loại xe, khu vực, kiểu đường hoặc biển',
    canAlert: false,
  );

  /// Chỉ chia bậc tham khảo NĐ 168/2024; KHÔNG phát cảnh báo/xử phạt.
  OverspeedBand assess(double? speedKmh, SpeedLimitResult result) {
    final limit = result.limitKmh;
    if (!result.canAlert || limit == null || speedKmh == null ||
        !speedKmh.isFinite || speedKmh < 0) {
      return OverspeedBand.unavailable;
    }
    final excess = speedKmh - limit;
    if (excess <= 0) return OverspeedBand.none;
    if (excess < 5) return OverspeedBand.belowFive;
    if (excess < 10) return OverspeedBand.fiveToUnderTen;
    if (excess <= 20) return OverspeedBand.tenToTwenty;
    if (excess <= 35) return OverspeedBand.overTwentyToThirtyFive;
    return OverspeedBand.overThirtyFive;
  }

  /// Chỉ phát hiện thấp hơn biển TỐI THIỂU cao tốc đã xác nhận.
  bool belowVerifiedMinimum(double? speedKmh, SpeedLimitResult result) =>
      result.canAlert && result.minKmh != null &&
      speedKmh != null && speedKmh.isFinite && speedKmh >= 0 &&
      speedKmh < result.minKmh!;
}
