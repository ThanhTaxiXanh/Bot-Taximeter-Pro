import 'package:flutter_test/flutter_test.dart';

import 'package:bot_taximeter_pro/features/map_tracking/data/reference_speed_signs.dart';

void main() {
  test('Parser chỉ giữ biển hợp lệ, ID không trùng và không suy đoán hướng', () {
    final records = ReferenceSpeedSigns.parse(
      'id,lat_e6,lon_e6,speed,direction\n'
      '1,21274100,106194600,40,255\n'
      '1,21274100,106194600,50,90\n'
      '2,21274200,106194700,60,45\n'
      '3,not-a-number,106194800,40,90\n'
      '4,95000000,106194800,40,90\n'
      '5,21274000,106194600,180,90\n'
      '6,21274000,106194600,60,300\n',
    );
    expect(records.length, 2);
    expect(records.first.id, 1);
    expect(records.first.kmh, 40);
    expect(records.first.direction, 255); // Chưa giải mã, không loại bỏ.
    expect(records.last.id, 2);
    expect(() => ReferenceSpeedSigns.parse('bad,header'), throwsFormatException);
  });

  test('Dữ liệu thử Bắc Giang đúng phạm vi, ngoài tỉnh không hiển thị', () {
    expect(ReferenceSpeedSigns.data.length, ReferenceSpeedSigns.pilotCount);
    expect(ReferenceSpeedSigns.data.length, 147);
    expect(ReferenceSpeedSigns.data.where((s) => s.direction == 255).length, 47);
    expect(ReferenceSpeedSigns.data.every((s) =>
        (s.lat - 21.2741).abs() <= 0.07501 &&
        (s.lon - 106.1946).abs() <= 0.07501), isTrue);
    final nearby = ReferenceSpeedSigns.nearby(21.2741, 106.1946);
    expect(nearby, isNotEmpty);
    expect(nearby.length, lessThanOrEqualTo(16));
    expect(ReferenceSpeedSigns.nearby(10, 104), isEmpty);
    expect(ReferenceSpeedSigns.nearby(double.nan, 106), isEmpty);
  });

  test('Marker tham khảo có giới hạn và nhãn chưa xác minh', () {
    final markers = ReferenceSpeedSigns.markersNear(21.2741, 106.1946);
    expect(markers.length, lessThanOrEqualTo(16));
    expect(markers, isNotEmpty);
    for (final marker in markers) {
      expect(marker.markerId.value, startsWith('sign-ref-'));
      expect(marker.infoWindow.title, contains('CHƯA XÁC MINH'));
      expect(marker.infoWindow.snippet, contains('không dùng để cảnh báo'));
    }
  });
}
