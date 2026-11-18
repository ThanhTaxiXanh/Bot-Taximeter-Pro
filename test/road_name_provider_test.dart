import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/map_tracking/data/road_name_provider.dart';

void main() {
  test('Chặn trực tiếp máy chủ Nominatim công cộng cho app taxi', () async {
    final provider = NominatimGeocodingProvider(
      baseUrl: 'https://nominatim.openstreetmap.org',
    );
    expect(provider.configured, isFalse);
    expect(await provider.reverse(21.28, 106.19), isNull);
  });

  test('Mặc định không gửi vị trí lên máy chủ', () async {
    final provider = NominatimGeocodingProvider(baseUrl: '');
    expect(provider.configured, false);
    expect(await provider.reverse(21.28, 106.2), isNull);
  });

  test('Cache 50m và giới hạn tối thiểu 1,2 giây', () async {
    var now = DateTime.utc(2026, 11, 18, 10);
    var calls = 0;
    final provider = NominatimGeocodingProvider(
      baseUrl: 'https://private.example.com/nominatim',
      clock: () => now,
      request: (lat, lon) async {
        calls++;
        return <String, dynamic>{
          'address': <String, dynamic>{'road': 'Đường Trần Phú'},
        };
      },
    );
    expect(await provider.reverse(21.279, 106.19), 'Đường Trần Phú');
    expect(await provider.reverse(21.27901, 106.19001), 'Đường Trần Phú');
    expect(calls, 1);
    expect(await provider.reverse(21.30, 106.19), isNull);
    expect(calls, 1);
    now = now.add(const Duration(seconds: 2));
    expect(await provider.reverse(21.30, 106.19), 'Đường Trần Phú');
    expect(calls, 2);
    expect(provider.cacheCount, 2);
  });

  test('Không trả đường nếu response không có road', () async {
    final provider = NominatimGeocodingProvider(
      request: (_, _) async => <String, dynamic>{
        'address': <String, dynamic>{'city': 'Bắc Giang'},
      },
    );
    expect(await provider.reverse(21.28, 106.19), isNull);
  });
}
