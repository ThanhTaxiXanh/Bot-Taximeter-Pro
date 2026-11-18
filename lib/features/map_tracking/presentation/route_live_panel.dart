import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';
import '../../../shared/shared_map_view.dart';
import '../../fare_meter/fare_calculator.dart';
import '../data/gps_tracker.dart';
import '../data/osrm_route_service.dart';
import '../data/place_search_service.dart';

/// Xem tuyến OSRM trước khi chạy, không tự thay đổi cước GPS trong chuyến.
class RouteLivePanel extends StatefulWidget {
  const RouteLivePanel({super.key,
    required this.startName, required this.endName, required this.stopName,
    required this.includeStop, required this.is3D, required this.traffic,
    this.startLatitude, this.startLongitude,
    this.endLatitude, this.endLongitude,
    required this.on3D, required this.on2D, required this.onTraffic,
    this.geocoder, this.router});
  final String startName, endName, stopName;
  final bool includeStop, is3D, traffic;
  final VoidCallback on3D, on2D, onTraffic;
  final String? startLatitude, startLongitude, endLatitude, endLongitude;
  final NominatimPlaceService? geocoder;
  final OsrmRouteService? router;

  @override
  State<RouteLivePanel> createState() => _RouteLivePanelState();
}

class _RouteLivePanelState extends State<RouteLivePanel> {
  late final NominatimPlaceService _geocoder =
      widget.geocoder ?? NominatimPlaceService.instance;
  late final OsrmRouteService _router =
      widget.router ?? OsrmRouteService.instance;
  List<PlannedRoute> _routes = const [];
  int _selected = 0;
  bool _loading = false;
  String? _error;
  FareConfig _config = const FareConfig();

  @override
  void initState() {
    super.initState();
    _readFareSettings();
  }

  @override
  void didUpdateWidget(covariant RouteLivePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startName != widget.startName ||
        oldWidget.endName != widget.endName ||
        oldWidget.stopName != widget.stopName ||
        oldWidget.includeStop != widget.includeStop) {
      _routes = const [];
      _selected = 0;
    }
  }

  Future<void> _readFareSettings() async {
    try {
      final p = await SharedPreferences.getInstance();
      final config = FareConfig.fromJson({
        'opening': p.getInt('fare_opening') ?? 30000,
        'tier1': p.getInt('fare_tier1') ?? 13000,
        'tier2': p.getInt('fare_tier2') ?? 11500,
        'tier3': p.getInt('fare_tier3') ?? 10000,
        'waitHour': p.getInt('fare_wait_hour') ?? 30000,
        'freeWait': p.getInt('fare_free_wait') ?? 5,
      });
      if (mounted) setState(() => _config = config);
    } catch (_) {
      // Không thay đổi biểu phí đang chạy nếu thiếu preferences.
    }
  }

  RoutePoint? _point(String? latitude, String? longitude) {
    final lat = double.tryParse(latitude ?? '');
    final lon = double.tryParse(longitude ?? '');
    if (lat == null || lon == null) return null;
    final point = RoutePoint(lat, lon);
    return point.valid ? point : null;
  }

  Future<RoutePoint> _resolve(String name, RoutePoint? chosen) async {
    if (chosen != null) return chosen;
    if (name.trim() == 'Vị trí hiện tại') {
      final fix = GpsTracker.instance.fix;
      if (fix == null || !GpsTracker.instance.hasGoodFix) {
        throw StateError('Chưa có GPS hợp lệ để chọn vị trí hiện tại');
      }
      return RoutePoint(fix.point.latitude, fix.point.longitude);
    }
    if (!_geocoder.configured) {
      throw StateError('Chưa cấu hình dịch vụ tìm địa chỉ được phép');
    }
    final results = await _geocoder.search(name);
    if (results.isEmpty) throw StateError('Không tìm được: ' + name);
    return RoutePoint(results.first.latitude, results.first.longitude);
  }

  Future<void> _calculate() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _routes = const [];
      _selected = 0;
    });
    try {
      final points = <RoutePoint>[
        await _resolve(widget.startName,
            _point(widget.startLatitude, widget.startLongitude)),
      ];
      if (widget.includeStop && widget.stopName.trim().isNotEmpty &&
          widget.stopName.trim() != 'Vị trí thuê xe') {
        points.add(await _resolve(widget.stopName, null));
      }
      points.add(await _resolve(widget.endName,
          _point(widget.endLatitude, widget.endLongitude)));
      final routes = await _router.route(points);
      if (mounted) setState(() => _routes = routes);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _routes.isEmpty ? null : _routes[_selected];
    final estimate = chosen == null ? null : FareCalculator(_config)
        .estimate(chosen.distanceMeters / 1000);
    final coordinates = chosen?.points.map((p) =>
        LatLng(p.latitude, p.longitude)).toList(growable: false);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('ĐỊNH TUYẾN THẬT · OSRM / OSM',
            style: TextStyle(fontSize: 12, color: AppColors.cyan)),
        FilledButton.icon(
          onPressed: _loading ? null : _calculate,
          icon: const Icon(Icons.route),
          label: const Text('Tính tuyến thật'),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Text(_error!,
            style: const TextStyle(color: AppColors.danger)),
        if (_routes.isNotEmpty) ...<Widget>[
          Wrap(spacing: 6, children: <Widget>[
            for (var i = 0; i < _routes.length; i++)
              ChoiceChip(
                label: Text(i == 0 ? 'Gợi ý OSRM' : 'Phương án ' + (i + 1).toString()),
                selected: _selected == i,
                onSelected: (_) => setState(() => _selected = i),
              ),
          ]),
        ],
        const SizedBox(height: 7),
        Wrap(spacing: 6, children: <Widget>[
          ChoiceChip(label: const Text('3D'), selected: widget.is3D,
              onSelected: (_) => widget.on3D()),
          ChoiceChip(label: const Text('2D'), selected: !widget.is3D,
              onSelected: (_) => widget.on2D()),
          ActionChip(label: Text(widget.traffic ? 'GT: Bật' : 'GT: Tắt'),
              onPressed: widget.onTraffic),
        ]),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(height: 215, child: SharedMapView(
            is3D: widget.is3D, isDark: false,
            trafficEnabled: widget.traffic, followVehicle: false,
            showRoute: chosen != null, routePoints: coordinates,
          )),
        ),
        if (chosen != null && estimate != null) ...<Widget>[
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2, childAspectRatio: 1.1,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 7, mainAxisSpacing: 7,
            children: <Widget>[
              StatCard(label: 'ETA (không tính kẹt xe)',
                  value: ((chosen.durationSeconds / 60).ceil()).toString() + ' phút',
                  icon: Icons.schedule),
              StatCard(label: 'Quãng đường', icon: Icons.route,
                  value: formatKm(chosen.distanceMeters / 1000)),
              StatCard(label: 'Cước từ (tham khảo)',
                  value: formatVnd(estimate.$1),
                  icon: Icons.payments_outlined),
              const StatCard(label: 'BOT', value: 'Chưa xác định',
                  icon: Icons.toll),
            ],
          ),
          const SizedBox(height: 5),
          Text('Khoảng cước: ' + formatVnd(estimate.$1) + ' đến ' +
              formatVnd(estimate.$2), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          const Text('Chỉ dẫn rẽ theo tuyến', style:
              TextStyle(fontWeight: FontWeight.bold)),
          if (chosen.turns.isEmpty)
            const Text('Máy chủ không trả về chỉ dẫn rẽ.'),
          for (final turn in chosen.turns.take(12))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(turn.instruction +
                  (turn.meters > 0 ? ' · ' + turn.meters.round().toString() + ' m' : ''),
                  style: const TextStyle(fontSize: 12)),
            ),
        ],
        const SizedBox(height: 7),
        const Text('Tuyến & ETA chỉ để tham khảo, không tính tình trạng '
            'kẹt xe hoặc phí BOT tự động. Cước chuyến đi vẫn theo GPS.',
            style: TextStyle(fontSize: 11, color: AppColors.muted)),
        const Text('© OpenStreetMap contributors · Dữ liệu định tuyến OSRM',
            style: TextStyle(fontSize: 10, color: AppColors.muted)),
      ],
    );
  }
}
