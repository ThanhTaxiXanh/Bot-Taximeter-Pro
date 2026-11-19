import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/speed_limit/speed_rules.dart';
import 'package:bot_taximeter_pro/features/speed_limit/speed_limit_engine.dart';

void main() {
  const engine = SpeedLimitEngine();
  const divided = Carriageway.dividedOrMultilaneOneWay;
  const single = Carriageway.twoWayOrSingleLaneOneWay;
  const groups = <VehicleClass, List<int>>{
    VehicleClass.lightPassengerOrTruck: [90, 80],
    VehicleClass.largePassengerOrTruck: [80, 70],
    VehicleClass.busMotorcycleOrOther: [70, 60],
    VehicleClass.trailerTanker: [60, 50],
  };

  group('Điều 6: mọi loại xe, khu vực và kiểu đường', () {
    for (final entry in groups.entries) {
      for (final area in [AreaType.populated, AreaType.outsidePopulated]) {
        for (final way in [divided, single]) {
          final expected = area == AreaType.populated
              ? (way == divided ? 60 : 50)
              : entry.value[way == divided ? 0 : 1];
          test(entry.key.toString() + '/' + area.name + '/' + way.name, () {
            final result = engine.resolve(RoadContext(
              vehicleClass: entry.key, areaType: area, carriageway: way));
            expect(result.limitKmh, expected);
            expect(result.minKmh, isNull);
            expect(result.source, SpeedLimitSource.rule);
            expect(result.canAlert, isTrue);
            expect(result.ruleRef, contains('Điều 6'));
          });
        }
      }
    }
  });

  test('16 dòng có legalBasis, articleRef và effectiveFrom', () {
    expect(SpeedRules.all, hasLength(16));
    for (final r in SpeedRules.all) {
      expect(r.legalBasis, contains('38/2024'));
      expect(r.articleRef, contains('Điều 6'));
      expect(r.effectiveFrom, '2025-01-01');
    }
  });

  test('Ưu tiên manual > posted đã xác minh > rule', () {
    final manual = engine.resolve(const RoadContext(
      areaType: AreaType.outsidePopulated, carriageway: divided,
      manualLimitKmh: 40, postedLimitKmh: 50, postedConfirmed: true));
    expect(manual.limitKmh, 40);
    expect(manual.source, SpeedLimitSource.manual);
    final posted = engine.resolve(const RoadContext(
      areaType: AreaType.outsidePopulated, carriageway: divided,
      postedLimitKmh: 50, postedConfirmed: true));
    expect(posted.limitKmh, 50);
    expect(posted.source, SpeedLimitSource.posted);
    expect(posted.canAlert, isTrue);
  });

  test('OSM chưa xác nhận chỉ hiển thị ~, không cấp cảnh báo', () {
    final r = engine.resolve(const RoadContext(
      areaType: AreaType.populated, carriageway: divided,
      postedLimitKmh: 45));
    expect(r.source, SpeedLimitSource.posted);
    expect(r.displayLabel, '~45');
    expect(r.canAlert, isFalse);
    expect(engine.assess(100, r), OverspeedBand.unavailable);
  });

  test('Đông dân cư suy đoán ruleGuess, không cảnh báo', () {
    final r = engine.resolve(const RoadContext(
      areaType: AreaType.populated, carriageway: single,
      areaInferred: true));
    expect(r.limitKmh, 50);
    expect(r.source, SpeedLimitSource.ruleGuess);
    expect(r.displayLabel, '~50');
    expect(r.canAlert, isFalse);
  });

  test('Không đủ ngữ cảnh hoặc cao tốc thiếu biển => unknown', () {
    for (final context in [
      const RoadContext(),
      const RoadContext(areaType: AreaType.populated),
      const RoadContext(areaType: AreaType.outsidePopulated,
        carriageway: divided, vehicleClass: VehicleClass.unknown),
      const RoadContext(areaType: AreaType.motorway, carriageway: divided),
      const RoadContext(areaType: AreaType.motorway,
        postedLimitKmh: 130, postedConfirmed: true),
    ]) {
      final r = engine.resolve(context);
      expect(r.displayLabel, '--');
      expect(r.source, SpeedLimitSource.unknown);
      expect(r.canAlert, isFalse);
      expect(engine.assess(150, r), OverspeedBand.unavailable);
    }
  });

  test('Cao tốc: chỉ dùng biển đã kiểm chứng; không mặc định 120/60', () {
    expect(SpeedRules.motorwayCeilingKmh, 120);
    expect(SpeedRules.motorwayGeneralFloorKmh, 60);
    final r = engine.resolve(const RoadContext(
      areaType: AreaType.motorway, postedLimitKmh: 100,
      postedMinKmh: 60, postedConfirmed: true));
    expect(r.limitKmh, 100);
    expect(r.minKmh, 60);
    expect(engine.belowVerifiedMinimum(59.9, r), isTrue);
    expect(engine.belowVerifiedMinimum(60, r), isFalse);
    final osm = engine.resolve(const RoadContext(
      areaType: AreaType.motorway, postedLimitKmh: 100,
      postedMinKmh: 60));
    expect(osm.minKmh, isNull);
    expect(engine.belowVerifiedMinimum(40, osm), isFalse);
  });

  test('Ngưỡng vượt 5,10,20,35 km/h: phân loại biên', () {
    final r = engine.resolve(const RoadContext(
      areaType: AreaType.populated, carriageway: single));
    const samples = <(double, OverspeedBand)>[
      (50, OverspeedBand.none),
      (50.01, OverspeedBand.belowFive),
      (54.99, OverspeedBand.belowFive),
      (55, OverspeedBand.fiveToUnderTen),
      (59.99, OverspeedBand.fiveToUnderTen),
      (60, OverspeedBand.tenToTwenty),
      (70, OverspeedBand.tenToTwenty),
      (70.01, OverspeedBand.overTwentyToThirtyFive),
      (85, OverspeedBand.overTwentyToThirtyFive),
      (85.01, OverspeedBand.overThirtyFive),
    ];
    for (final sample in samples) {
      expect(engine.assess(sample.$1, r), sample.$2);
    }
    expect(engine.assess(-1, r), OverspeedBand.unavailable);
    expect(engine.assess(double.nan, r), OverspeedBand.unavailable);
    expect(engine.assess(double.infinity, r), OverspeedBand.unavailable);
    expect(engine.assess(null, r), OverspeedBand.unavailable);
  });
}
