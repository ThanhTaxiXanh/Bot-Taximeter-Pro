import 'package:flutter_test/flutter_test.dart';

import 'package:bot_taximeter_pro/features/map_tracking/data/imported_road_signs.dart';

void main() {
  test('Nhận đúng tiêu đề hai CSV, kể cả UTF-8 BOM', () {
    expect(ImportedRoadSigns.headerKind(ImportedRoadSigns.trafficHeader), false);
    expect(ImportedRoadSigns.headerKind(ImportedRoadSigns.speedHeader), true);
    expect(ImportedRoadSigns.headerKind(
        '\uFEFF' + ImportedRoadSigns.trafficHeader), false);
    expect(ImportedRoadSigns.headerKind('id,lat,lon'), isNull);
  });

  test('Biển tổng hợp giữ nguyên ID, loại, hướng và meta của người thu thập', () {
    final a = ImportedRoadSign.parse(
      '0,105.865760,21.008960,43,160,0,12,2626,13233',
      speedOnly: false,
    )!;
    expect(a.id, 0);
    expect(a.code, 43);
    expect(a.direction, 160);
    expect(a.rawValue, '0');
    expect(a.meta, '12');
    expect(a.lat, 21.008960);
    expect(a.lon, 105.865760);
    expect(a.title, contains('mã 43'));
    expect(a.details, contains('hướng 160'));

    final speed = ImportedRoadSign.parse(
      '1,104.830584,8.571200,1,102,40,4,1071,13103',
      speedOnly: false,
    )!;
    expect(speed.title, contains('40 km/h'));
  });

  test('CSV tốc độ hỗ trợ trực tiếp 38.757 dòng cùng schema gốc', () {
    final s = ImportedRoadSign.parse(
      '1,104.830584,8.571200,40,102,1', speedOnly: true,
    )!;
    expect(s.code, 1);
    expect(s.rawValue, '40');
    expect(s.direction, 102);
    expect(s.meta, isEmpty);
    expect(s.dbRow['id'], 1);
  });

  test('Loại bỏ điểm, mã hướng hoặc tọa độ sai; không suy đoán giá trị', () {
    const good = '1,104.830584,8.571200,40,255,1';
    expect(ImportedRoadSign.parse(good, speedOnly: true)?.direction, 255);
    for (final bad in <String>[
      '1,999,8.571200,40,102,1',
      '1,104.8,99,40,102,1',
      '1,NaN,8.5,40,102,1',
      '1,104.8,8.5,40,999,1',
      '-1,104.8,8.5,40,255,1',
      '1,104.8,8.5,40,255',
    ]) {
      expect(ImportedRoadSign.parse(bad, speedOnly: true), isNull);
    }
  });
}
