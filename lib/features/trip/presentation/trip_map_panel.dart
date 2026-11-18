import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';
import '../../../shared/shared_map_view.dart';
import '../../map_tracking/data/gps_tracker.dart';
import '../../map_tracking/presentation/home_widgets.dart';

/// Bản đồ chuyến đi được tách riêng để TripPage dưới 300 dòng.
class TripMapPanel extends StatelessWidget {
  const TripMapPanel({
    super.key, required this.mapKey,
    required this.is3D, required this.traffic,
    required this.follow, required this.on3D,
    required this.on2D, required this.onTraffic,
    required this.onFollowChanged, required this.onLimitTap,
  });

  final GlobalKey<SharedMapViewState> mapKey;
  final bool is3D;
  final bool traffic;
  final bool follow;
  final VoidCallback on3D, on2D, onTraffic, onLimitTap;
  final ValueChanged<bool> onFollowChanged;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(height: 218, child: Stack(children: <Widget>[
      Positioned.fill(child: SharedMapView(
        key: mapKey, is3D: is3D, isDark: true,
        trafficEnabled: traffic, followVehicle: follow,
        showRoute: true, routeIndex: 0,
        vehiclePosition: GpsTracker.instance.fix == null ? null
            : LatLng(GpsTracker.instance.fix!.point.latitude,
                GpsTracker.instance.fix!.point.longitude),
        bearing: GpsTracker.instance.fix?.point.headingDegrees ?? 0,
        onFollowChanged: onFollowChanged,
      )),
      Positioned(top: 6, left: 6, child: HomeSpeedPanel(
        limitKmh: 60,
        speedKmh: GpsTracker.instance.fix?.speedKmh.round() ??
            (GpsTracker.useMock ? 42 : 0),
        onLimitTap: onLimitTap,
      )),
      Positioned(top: 5, right: 5, child: SizedBox(
        width: 60, height: 203,
        child: FittedBox(
          fit: BoxFit.scaleDown, alignment: Alignment.topCenter,
          child: MapControlButtons(
            is3D: is3D, trafficEnabled: traffic,
            on3D: on3D, on2D: on2D,
            onTraffic: onTraffic,
            onRecenter: () => mapKey.currentState?.recenter(),
          ),
        ),
      )),
      Positioned(
        left: 26, right: 26, bottom: 7,
        child: GlassCard(
          onTap: () => GpsTracker.instance.refreshRoadName(),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
          child: Text(
            GpsTracker.instance.roadName == null
                ? (GpsTracker.useMock
                    ? 'Đường Trần Nhân Vũ · BẢN ĐỒ MẪU'
                    : 'Chạm để lấy tên đường GPS')
                : '${GpsTracker.instance.roadName} · © OpenStreetMap contributors',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white, fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ])),
  );
}
