import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../map_tracking/data/osrm_route_service.dart';
import '../../map_tracking/data/place_search_service.dart';
import '../../map_tracking/data/routing_server_config.dart';
import 'settings_widgets.dart';

/// Cấu hình đầu cuối được cấp phép trực tiếp trên điện thoại.
class RoutingServerSettings extends StatefulWidget {
  const RoutingServerSettings({super.key});

  @override
  State<RoutingServerSettings> createState() => _RoutingServerSettingsState();
}

class _RoutingServerSettingsState extends State<RoutingServerSettings> {
  final _geocoding = TextEditingController();
  final _routing = TextEditingController();
  bool _ready = false, _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _geocoding.text = prefs.getString(geocodingServerKey) ??
          NominatimPlaceService.instance.baseUrl;
      _routing.text = prefs.getString(osrmServerKey) ??
          OsrmRouteService.instance.baseUrl;
    } catch (_) {
      _geocoding.text = NominatimPlaceService.instance.baseUrl;
      _routing.text = OsrmRouteService.instance.baseUrl;
    }
    if (mounted) setState(() => _ready = true);
  }

  bool _valid(String value, {required bool geocoding}) {
    if (value.isEmpty) return true; // Xóa URL nghĩa là tắt dịch vụ.
    final uri = Uri.tryParse(value);
    if (uri == null || uri.hasQuery || uri.hasFragment ||
        uri.userInfo.isNotEmpty) return false;
    return geocoding
        ? NominatimPlaceService(baseUrl: value).configured
        : OsrmRouteService(baseUrl: value).configured;
  }

  Future<void> _save() async {
    if (_saving || !_ready) return;
    final geo = _geocoding.text.trim();
    final route = _routing.text.trim();
    if (!_valid(geo, geocoding: true) ||
        !_valid(route, geocoding: false)) {
      setState(() => _message = 'Chỉ dùng URL HTTPS hợp lệ của máy chủ '
          'được phép; không dùng Nominatim công cộng hoặc OSRM demo.');
      return;
    }
    setState(() { _saving = true; _message = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(geocodingServerKey, geo);
      await prefs.setString(osrmServerKey, route);
      NominatimPlaceService.instance.setBaseUrl(geo);
      OsrmRouteService.instance.setBaseUrl(route);
      if (mounted) setState(() =>
          _message = 'Đã lưu trên thiết bị. Mở Tìm kiếm hoặc Lập tuyến để thử.');
    } catch (_) {
      if (mounted) setState(() => _message = 'Không lưu được URL máy chủ.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _geocoding.dispose();
    _routing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsSection(
    title: 'Máy chủ tìm địa chỉ & định tuyến', icon: Icons.cloud_outlined,
    children: <Widget>[
      const Text('Chỉ cấu hình máy chủ riêng hoặc nhà cung cấp cho phép. '
          'Để trống nếu chưa có máy chủ. Không nhập API key trong URL.',
          style: TextStyle(color: AppColors.muted, fontSize: 11)),
      SettingsField(label: 'Nominatim HTTPS', controller: _geocoding,
          hint: 'https://geocoding.example.com'),
      SettingsField(label: 'OSRM HTTPS', controller: _routing,
          hint: 'https://routing.example.com'),
      const SizedBox(height: 5),
      FilledButton.icon(
        onPressed: !_ready || _saving ? null : _save,
        icon: const Icon(Icons.save),
        label: const Text('Lưu máy chủ tuyến'),
      ),
      if (_message != null)
        Text(_message!, style: const TextStyle(
          color: AppColors.cyan, fontSize: 12)),
      const Text('© OpenStreetMap contributors. Không có API mặc định; '
          'không tự tìm địa chỉ khi đang gõ.',
          style: TextStyle(color: AppColors.muted, fontSize: 11)),
    ],
  );
}
