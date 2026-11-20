import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/core/app_config.dart';
import 'package:bot_taximeter_pro/features/fare_meter/fare_calculator.dart';
import 'package:bot_taximeter_pro/features/map_tracking/data/gps_tracker.dart';
import 'package:bot_taximeter_pro/shared/shared_map_view.dart';

/// Rào chắn cho bản debug; không thay thế kiểm thử GPS/Maps trên thiết bị.
void main() {
  test('Package Android và bảy route không thay đổi ngoài ý muốn', () {
    expect(AppConfig.packageName, 'vn.bottaximeter.bot_taximeter_pro');
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    expect(RegExp(r'\bGoRoute\s*\(').allMatches(router).length, 7);
    for (final path in <String>[
      "home = '/'", "search = '/search'", "route = '/route'",
      "trip = '/trip'", "history = '/history'",
      "receipt = '/receipt'", "settings = '/settings'",
    ]) {
      expect(router, contains(path));
    }
  });

  test('Google Map chỉ dùng SDK Android, không gắn Map ID tính phí', () {
    final source =
        File('lib/shared/shared_map_view.dart').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(source, contains('GoogleMap('));
    expect(source, contains('trafficEnabled: widget.trafficEnabled'));
    expect(source, contains('style: widget.isDark ? _darkStyle : _lightStyle'));
    expect(RegExp(r'\b(?:mapId|cloudMapId)\s*:').hasMatch(source), isFalse);
    expect(RegExp(
      r'^  google_maps_flutter: [0-9]+\.[0-9]+\.[0-9]+$',
      multiLine: true,
    ).hasMatch(pubspec), isTrue);
    for (final paidSdk in <String>[
      'google_maps_webservice:', 'google_places_flutter:',
      'google_directions_api:', 'google_maps_flutter_web:',
    ]) {
      expect(pubspec, isNot(contains(paidSdk)));
    }
  });

  test('CI không tải native Maps/GPS; nhịp chuyến được giữ nguyên', () {
    expect(SharedMapView.useMock, isTrue);
    expect(GpsTracker.useMock, isTrue);
    expect(GpsPowerPolicy.interval(trip: true),
        const Duration(seconds: 1));
    expect(GpsPowerPolicy.distanceFilter(trip: true), 0);
    expect(GpsPowerPolicy.interval(trip: false),
        const Duration(seconds: 5));
    expect(GpsPowerPolicy.distanceFilter(trip: false), 10);
  });

  test('Luật làm tròn 500 đồng và BOT sau làm tròn', () {
    expect(roundVnd(30500), 30000);
    expect(roundVnd(30501), 31000);
    final fare = const FareCalculator(FareConfig()).calculate(
      distanceKm: 1.5, waitingSeconds: 360, tollFee: 5000,
    );
    expect(fare.waitFee, 500);
    expect(fare.rounded, 30000);
    expect(fare.total, 35000);
  });
}
