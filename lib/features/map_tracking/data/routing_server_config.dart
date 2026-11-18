import 'package:shared_preferences/shared_preferences.dart';

import 'osrm_route_service.dart';
import 'place_search_service.dart';
import 'road_name_provider.dart';

const geocodingServerKey = 'routing_geocoding_server';
const osrmServerKey = 'routing_osrm_server';

/// Khôi phục máy chủ tùy chỉnh khi khởi động. Không gọi mạng.
Future<void> loadSavedRoutingServers() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    NominatimPlaceService.instance.setBaseUrl(
        prefs.getString(geocodingServerKey) ?? geocodingBaseUrl);
    OsrmRouteService.instance.setBaseUrl(
        prefs.getString(osrmServerKey) ?? routingBaseUrl);
  } catch (_) {
    // Không ngăn ứng dụng khởi động khi thiếu preferences.
  }
}
