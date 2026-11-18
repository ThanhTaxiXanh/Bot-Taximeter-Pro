import 'package:go_router/go_router.dart';
import '../../features/trip/trip_controller.dart';

import '../../features/map_tracking/presentation/home_page.dart';
import '../../features/map_tracking/presentation/search_page.dart';
import '../../features/map_tracking/presentation/route_page.dart';
import '../../features/trip/presentation/trip_page.dart';
import '../../features/history/presentation/history_page.dart';
import '../../features/receipt/presentation/receipt_page.dart';
import '../../features/settings/presentation/settings_page.dart';

/// Bảy tuyến, giữ nguyên đường dẫn và các nhãn smoke test.
abstract final class AppRouter {
  static const String home = '/';
  static const String search = '/search';
  static const String route = '/route';
  static const String trip = '/trip';
  static const String history = '/history';
  static const String receipt = '/receipt';
  static const String settings = '/settings';

  static GoRouter createRouter({TripController? tripController}) => GoRouter(
    initialLocation: home,
    routes: <RouteBase>[
      GoRoute(path: home, builder: (_, _) => const HomePage()),
      GoRoute(path: search, builder: (_, _) => const SearchPage()),
      GoRoute(
        path: route,
        builder: (_, state) {
          final extra = state.extra;
          final points = extra is Map<String, String> ? extra : null;
          return RoutePage(
            initialStart: points?['start'],
            initialEnd: points?['end'],
            initialStartLatitude: points?['startLat'],
            initialStartLongitude: points?['startLon'],
            initialEndLatitude: points?['endLat'],
            initialEndLongitude: points?['endLon'],
          );
        },
      ),
      GoRoute(path: trip, builder: (_, _) =>
          TripPage(controller: tripController)),
      GoRoute(path: history, builder: (_, _) => const HistoryPage()),
      GoRoute(
        path: receipt,
        builder: (_, state) {
          final extra = state.extra;
          return ReceiptPage(
            snapshot: extra is Map<String, String>
                ? extra : const <String, String>{},
          );
        },
      ),
      GoRoute(path: settings, builder: (_, _) => const SettingsPage()),
    ],
  );
}
