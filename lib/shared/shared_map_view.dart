import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';
import '../features/map_tracking/presentation/mock_travel_data.dart';
import '../features/map_tracking/presentation/home_map_mock.dart';

/// Một widget Google Maps dùng chung trên Home, Tuyến đường, Đang chạy.
/// Marker chỉ được hiển thị khi truyền vào vị trí GPS đã lọc.
class SharedMapView extends StatefulWidget {
  const SharedMapView({
    super.key, required this.is3D, required this.isDark,
    required this.trafficEnabled, required this.followVehicle,
    this.showRoute = false, this.routeIndex = 0,
    this.onFollowChanged,
    this.vehiclePosition,
    this.bearing = 0,
    this.zoom = 17,
  });

  static const LatLng demoVehiclePosition = LatLng(21.2741, 106.1946);
  final bool is3D;
  final bool isDark;
  final bool trafficEnabled;
  final bool followVehicle;
  final bool showRoute;
  final int routeIndex;
  final ValueChanged<bool>? onFollowChanged;
  final LatLng? vehiclePosition;
  final double bearing;
  final double zoom;

  /// Widget test thông thường và CI luôn dùng Canvas thay vì native Maps.
  static bool get useMock =>
      kCI || (!kIsWeb && Platform.environment['FLUTTER_TEST'] == 'true');

  @override
  State<SharedMapView> createState() => SharedMapViewState();
}

class SharedMapViewState extends State<SharedMapView> {
  GoogleMapController? _controller;
  BitmapDescriptor? _arrowIcon;
  String? _darkStyle;
  String? _lightStyle;
  double _savedTilt = 60;
  bool _programmaticMove = false;

  // Ba tuyến demo ở Bắc Giang, không phải kết quả định tuyến thực tế.
  static const List<List<LatLng>> _demoRoutes = <List<LatLng>>[
    <LatLng>[
      LatLng(21.2726, 106.1916), LatLng(21.2730, 106.1930),
      LatLng(21.2741, 106.1946), LatLng(21.2756, 106.1950),
      LatLng(21.2763, 106.1962),
    ],
    <LatLng>[
      LatLng(21.2726, 106.1916), LatLng(21.2738, 106.1922),
      LatLng(21.2754, 106.1935), LatLng(21.2763, 106.1962),
    ],
    <LatLng>[
      LatLng(21.2726, 106.1916), LatLng(21.2721, 106.1940),
      LatLng(21.2742, 106.1965), LatLng(21.2763, 106.1962),
    ],
  ];

  @override
  void initState() {
    super.initState();
    if (!SharedMapView.useMock) {
      _loadStyles();
      _loadArrow();
      _loadTilt();
    }
  }

  Future<void> _loadStyles() async {
    try {
      final styles = await Future.wait<String>(<Future<String>>[
        rootBundle.loadString('assets/map_styles/dark.json'),
        rootBundle.loadString('assets/map_styles/light.json'),
      ]);
      if (mounted) setState(() {
        _darkStyle = styles[0];
        _lightStyle = styles[1];
      });
    } catch (_) {
      // Khi không đọc được file style, SDK dùng bản đồ mặc định.
    }
  }

  Future<void> _loadTilt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _savedTilt = (prefs.getDouble('map_tilt') ?? 60)
          .clamp(15.0, 80.0).toDouble();
      _recenter();
    } catch (_) {
      // Bỏ qua nếu thiết bị chưa có cấu hình.
    }
  }

  Future<void> _loadArrow() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final path = Path()
      ..moveTo(40, 4)
      ..lineTo(74, 73)
      ..lineTo(40, 57)
      ..lineTo(6, 73)
      ..close();
    canvas.drawShadow(path, const Color(0xFF127BFF), 11, true);
    canvas.drawPath(path, Paint()..color = const Color(0xFF1375EA));
    canvas.drawPath(path, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
    final picture = recorder.endRecording();
    final image = await picture.toImage(80, 80);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (!mounted || bytes == null) return;
    setState(() => _arrowIcon =
        BitmapDescriptor.bytes(bytes.buffer.asUint8List()));
  }

  CameraPosition get _camera => CameraPosition(
    target: widget.vehiclePosition ?? SharedMapView.demoVehiclePosition,
    zoom: widget.zoom,
    bearing: widget.bearing,
    tilt: widget.is3D ? _savedTilt : 0,
  );

  Future<void> _recenter() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    _programmaticMove = true;
    try {
      await controller.animateCamera(CameraUpdate.newCameraPosition(_camera));
    } catch (_) {
      _programmaticMove = false;
    }
  }

  /// Gọi từ nút định vị để bật lại chế độ Follow xe.
  void recenter() {
    widget.onFollowChanged?.call(true);
    _recenter();
  }

  @override
  void didUpdateWidget(covariant SharedMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.is3D != widget.is3D ||
        oldWidget.bearing != widget.bearing ||
        oldWidget.zoom != widget.zoom ||
        (widget.followVehicle &&
         (oldWidget.vehiclePosition != widget.vehiclePosition ||
          !oldWidget.followVehicle))) {
      _recenter();
    }
  }

  Set<Polyline> get _polylines {
    if (!widget.showRoute) return const <Polyline>{};
    return <Polyline>{
      for (var i = 0; i < _demoRoutes.length; i++)
        Polyline(
          polylineId: PolylineId('demo-$i'),
          points: _demoRoutes[i],
          color: i == widget.routeIndex % 3
              ? const Color(0xFF006EFF)
              : const Color(0xFF95A3B7),
          width: i == widget.routeIndex % 3 ? 7 : 4,
          zIndex: i == widget.routeIndex % 3 ? 2 : 0,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (SharedMapView.useMock) {
      // Không tạo GoogleMap; an toàn trên widget test và Android CI.
      if (widget.showRoute) {
        return MockRouteMap(selectedRoute: widget.routeIndex % 3);
      }
      return HomeMockMap(
        is3D: widget.is3D,
        isDark: widget.isDark,
        traffic: widget.trafficEnabled,
      );
    }
    return Stack(children: <Widget>[
      Positioned.fill(child: GoogleMap(
        initialCameraPosition: _camera,
        style: widget.isDark ? _darkStyle : _lightStyle,
        trafficEnabled: widget.trafficEnabled,
        buildingsEnabled: widget.is3D,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        zoomControlsEnabled: false,
        compassEnabled: true,
        markers: <Marker>{
          if (widget.vehiclePosition != null)
            Marker(
              markerId: const MarkerId('gps-vehicle'),
              position: widget.vehiclePosition!,
              icon: _arrowIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
              flat: true,
              anchor: const Offset(.5, .5),
              rotation: widget.bearing,
              infoWindow: const InfoWindow(title: 'Vị trí GPS thiết bị'),
            ),
        },
        polylines: _polylines,
        onMapCreated: (controller) {
          _controller = controller;
          if (widget.followVehicle) _recenter();
        },
        onCameraMoveStarted: () {
          if (_programmaticMove) return;
          if (widget.followVehicle) widget.onFollowChanged?.call(false);
        },
        onCameraIdle: () => _programmaticMove = false,
      )),
      Positioned(left: 5, bottom: 4, child: IgnorePointer(
        child: Text(
          widget.vehiclePosition == null
              ? 'GPS CHƯA XÁC ĐỊNH · KHÔNG CÓ MARKER'
              : 'VỊ TRÍ GPS · TUYẾN ĐƯỜNG VẪN LÀ MẪU',
          style: TextStyle(
            color: Colors.white, fontSize: 9,
            shadows: <Shadow>[
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
      )),
    ]);
  }
}
