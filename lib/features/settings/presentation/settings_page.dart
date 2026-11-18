import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import 'settings_widgets.dart';
import 'routing_server_settings.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  final _bank = TextEditingController();
  final _owner = TextEditingController();
  final _account = TextEditingController();
  final _greeting = TextEditingController(text: 'Xin chào quý khách!');
  final _fareFields = <TextEditingController>[
    TextEditingController(text: '30000'), TextEditingController(text: '13000'),
    TextEditingController(text: '11500'), TextEditingController(text: '10000'),
    TextEditingController(text: '30000'), TextEditingController(text: '5'),
  ];
  bool _autoWait = false;
  bool _is3D = true, _follow = true, _dark = true, _traffic = true;
  bool _roads = true, _auto3D = true, _sound = true, _jam = true;
  bool _vibration = true, _simple = false, _transfer = false;
  bool _ready = false, _saving = false;
  double _tilt = 60;
  String _vehicle = 'Ô tô con', _area = 'Tự động', _fontSize = 'Vừa';
  @override
  void initState() {
    super.initState();
    _load();
  }
  @override
  void dispose() {
    _bank.dispose();
    _owner.dispose();
    _account.dispose();
    _greeting.dispose();
    for (final field in _fareFields) { field.dispose(); }
    super.dispose();
  }
  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _is3D = p.getBool('map_3d') ?? true;
        _follow = p.getBool('follow_car') ?? true;
        _dark = p.getBool('map_dark') ?? true;
        _traffic = p.getBool('map_traffic') ?? true;
        _roads = p.getBool('map_roads') ?? true;
        _auto3D = p.getBool('auto_3d') ?? true;
        _sound = p.getBool('alert_sound') ?? true;
        _jam = p.getBool('alert_traffic') ?? true;
        _vibration = p.getBool('alert_vibration') ?? true;
        _simple = p.getBool('simple_mode') ?? false;
        _transfer = p.getBool('default_transfer') ?? false;
        _tilt = (p.getDouble('map_tilt') ?? 60).clamp(15, 80).toDouble();
        _vehicle = p.getString('vehicle_type') ?? 'Ô tô con';
        _area = p.getString('road_area') ?? 'Tự động';
        _fontSize = p.getString('font_size') ?? 'Vừa';
        _bank.text = p.getString('bank_name') ?? '';
        _owner.text = p.getString('bank_owner') ?? '';
        _account.text = p.getString('bank_account') ?? '';
        _greeting.text = p.getString('led_greeting') ?? 'Xin chào quý khách!';
        const keys = <String>['fare_opening','fare_tier1','fare_tier2',
            'fare_tier3','fare_wait_hour','fare_free_wait'];
        const defaults = <int>[30000,13000,11500,10000,30000,5];
        for (var i = 0; i < keys.length; i++) {
          _fareFields[i].text = '${p.getInt(keys[i]) ?? defaults[i]}';
        }
        _autoWait = p.getBool('fare_auto_wait') ?? false;
        _ready = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _ready = true);
        _notice('Không đọc được cài đặt đã lưu. Đang dùng giá trị mặc định.');
      }
    }
  }
  void _notice(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));
  Future<void> _save() async {
    if (_saving || !_ready) return;
    const keys = <String>['fare_opening','fare_tier1','fare_tier2',
      'fare_tier3','fare_wait_hour','fare_free_wait'];
    final values = _fareFields.map((c) => int.tryParse(c.text.trim())).toList();
    if (values.any((v) => v == null || v < 0) || values.last! > 1440) {
      _notice('Biểu phí không hợp lệ; nhập số nguyên không âm.');
      return;
    }
    setState(() => _saving = true);
    try {
      final p = await SharedPreferences.getInstance();
      final results = await Future.wait<bool>(<Future<bool>>[
        p.setBool('map_3d', _is3D), p.setBool('follow_car', _follow),
        p.setBool('map_dark', _dark), p.setBool('map_traffic', _traffic),
        p.setBool('map_roads', _roads), p.setBool('auto_3d', _auto3D),
        p.setBool('alert_sound', _sound), p.setBool('alert_traffic', _jam),
        p.setBool('alert_vibration', _vibration),
        p.setBool('simple_mode', _simple),
        p.setBool('default_transfer', _transfer),
        p.setDouble('map_tilt', _tilt),
        p.setString('vehicle_type', _vehicle),
        p.setString('road_area', _area),
        p.setString('font_size', _fontSize),
        p.setString('bank_name', _bank.text.trim()),
        p.setString('bank_owner', _owner.text.trim()),
        p.setString('bank_account', _account.text.trim()),
        p.setString('led_greeting', _greeting.text.trim()),
      ]);
      for (var i = 0; i < keys.length; i++) {
        if (!await p.setInt(keys[i], values[i]!)) {
          throw StateError('Không lưu được biểu phí');
        }
      }
      if (!await p.setBool('fare_auto_wait', _autoWait)) {
        throw StateError('Không lưu tự động chờ');
      }
      if (results.contains(false)) throw StateError('Không lưu được');
      if (mounted) _notice('Đã lưu cài đặt trên thiết bị.');
    } catch (_) {
      if (mounted) _notice('Lưu thất bại. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  void _reset() => setState(() {
    _is3D = true; _follow = true; _dark = true; _traffic = true;
    _roads = true; _auto3D = true; _sound = true; _jam = true;
    _vibration = true; _simple = false; _transfer = false;
    _tilt = 60; _vehicle = 'Ô tô con'; _area = 'Tự động';
    _fontSize = 'Vừa'; _bank.clear(); _owner.clear(); _account.clear();
    _greeting.text = 'Xin chào quý khách!';
    const defaults = <int>[30000,13000,11500,10000,30000,5];
    for (var i = 0; i < defaults.length; i++) {
      _fareFields[i].text = '${defaults[i]}';
    }
    _autoWait = false;
    _notice('Đã đặt mặc định trên màn hình. Nhấn Lưu cài đặt để ghi lại.');
  });
  Widget _mapSettings() => SettingsSection(
    title: 'Bản đồ & Camera', icon: Icons.map,
    children: <Widget>[
      SettingsChoice( label: 'Google Maps', icon: Icons.layers, options: const <String>['2D', '3D'], value: _is3D ? '3D' : '2D', onChanged: (v) => setState(() => _is3D = v == '3D'),
      ),
      SettingsToggle(
        title: 'Theo xe', icon: Icons.local_taxi, value: _follow, onChanged: (v) => setState(() => _follow = v),
      ),
      Row(children: <Widget>[
        const Expanded(child: Text('Góc nghiêng camera')),
        Text('${_tilt.round()}°',
            style: const TextStyle(color: AppColors.cyan)),
      ]),
      Slider( value: _tilt, min: 15, max: 80, divisions: 65, label: '${_tilt.round()}°', onChanged: (v) => setState(() => _tilt = v),
      ),
      SettingsChoice( label: 'Chế độ hiển thị', icon: Icons.brightness_4, options: const <String>['Sáng', 'Tối'], value: _dark ? 'Tối' : 'Sáng', onChanged: (v) => setState(() => _dark = v == 'Tối'),
      ),
      SettingsToggle(
        title: 'Giao thông', subtitle: 'Hiển thị tình trạng kẹt xe', icon: Icons.traffic, value: _traffic, onChanged: (v) => setState(() => _traffic = v),
      ),
      SettingsToggle(
        title: 'Hiển thị tên đường', icon: Icons.alt_route, value: _roads, onChanged: (v) => setState(() => _roads = v),
      ),
      const Divider(color: AppColors.border),
      SettingsMapPreview(
        is3D: _is3D, isDark: _dark, traffic: _traffic,
        tilt: _tilt, roadNames: _roads,
      ),
    ],
  );
  Widget _tripSettings() => SettingsSection(
    title: 'Điều khiển chuyến đi', icon: Icons.local_taxi,
    children: <Widget>[
      SettingsToggle(
        title: 'Tự bật 3D khi bắt đầu', value: _auto3D, icon: Icons.view_in_ar, onChanged: (v) => setState(() => _auto3D = v),
      ),
      SettingsToggle(
        title: 'Âm báo tốc độ', value: _sound, icon: Icons.volume_up, onChanged: (v) => setState(() => _sound = v),
      ),
      SettingsToggle(
        title: 'Cảnh báo kẹt xe', value: _jam, icon: Icons.traffic, onChanged: (v) => setState(() => _jam = v),
      ),
      SettingsToggle(
        title: 'Rung cảnh báo', value: _vibration, icon: Icons.vibration, onChanged: (v) => setState(() => _vibration = v),
      ),
      SettingsChoice( label: 'Loại xe', icon: Icons.directions_car, options: const <String>['Ô tô con', 'Xe đến 30 chỗ'], value: _vehicle, onChanged: (v) => setState(() => _vehicle = v),
      ),
      SettingsChoice( label: 'Khu vực đang chạy', icon: Icons.signpost, options: const <String>[
          'Tự động', 'Trong khu đông dân cư',
          'Ngoài khu đông dân cư', 'Cao tốc',
        ], value: _area, onChanged: (v) => setState(() => _area = v),
      ),
    ],
  );
  Widget _paymentSettings() => SettingsSection(
    title: 'Thanh toán', icon: Icons.account_balance_wallet,
    children: <Widget>[
      SettingsField(label: 'Ngân hàng', controller: _bank,
          hint: 'Chưa cấu hình'),
      SettingsField(label: 'Chủ tài khoản', controller: _owner),
      SettingsField( label: 'Số tài khoản', controller: _account, keyboardType: TextInputType.number,
      ),
      SettingsToggle(
        title: 'QR chuyển khoản mặc định', subtitle: 'Chỉ điều chỉnh giao diện QR mẫu ở Bước 7', icon: Icons.qr_code, value: _transfer, onChanged: (v) => setState(() => _transfer = v),
      ),
      const Text('VietQR thanh toán thật sẽ được tích hợp ở Bước 13. '
          'Không nhập mật khẩu hay mã OTP.',
          style: TextStyle(color: AppColors.muted, fontSize: 11)),
    ],
  );
  Widget _displaySettings() => SettingsSection(
    title: 'Giao diện', icon: Icons.palette_outlined,
    children: <Widget>[
      SettingsField(label: 'Câu chào LED', controller: _greeting),
      SettingsChoice( label: 'Kích thước chữ', icon: Icons.text_fields, options: const <String>['Nhỏ', 'Vừa', 'Lớn'], value: _fontSize, onChanged: (v) => setState(() => _fontSize = v),
      ),
      SettingsToggle(
        title: 'Chế độ đơn giản', subtitle: 'Tùy chọn sẽ áp dụng ở bước hoàn thiện', value: _simple, icon: Icons.layers, onChanged: (v) => setState(() => _simple = v),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Cài đặt & Tùy chọn bản đồ',
    helpText: 'Tùy chỉnh bản đồ Google Maps, camera lái xe, '
        'cảnh báo và thanh toán.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!_ready) const LinearProgressIndicator(),
        _mapSettings(), const SizedBox(height: 11),
        const RoutingServerSettings(), const SizedBox(height: 11),
        _tripSettings(), const SizedBox(height: 11),
        _paymentSettings(), const SizedBox(height: 11),
        _displaySettings(), const SizedBox(height: 11),
        SettingsSection(title: 'Biểu phí & Phí chờ', icon: Icons.payments_outlined, children: <Widget>[
            for (var i = 0; i < _fareFields.length; i++)
              SettingsField(controller: _fareFields[i], keyboardType: TextInputType.number, label: const <String>[
                  'Mở cửa 1,5 km (đ)', '1,5–30 km (đ/km)',
                  '30–50 km (đ/km)', 'Trên 50 km (đ/km)',
                  'Chờ (đ/giờ)', 'Phút chờ miễn phí (0/3/5/10/15/tùy chỉnh)',
                ][i]),
            SettingsToggle(title: 'Tự vào Waiting khi dưới 3 km/h sau 10 giây', value: _autoWait, onChanged: (v) => setState(() => _autoWait = v)),
            const Text('Chỉ là công cụ tham khảo, chưa kiểm định.',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ]),
        const SizedBox(height: 12),
        Row(children: <Widget>[
          Expanded(child: NeonButton( label: 'Lưu cài đặt', icon: Icons.save,
            onPressed: _saving || !_ready ? null : _save,
          )),
          const SizedBox(width: 8),
          Expanded(child: NeonButton( label: 'Khôi phục mặc định', icon: Icons.restore, primary: false, onPressed: _saving ? null : _reset,
          )),
        ]),
        const SizedBox(height: 10),
      ],
    ),
  );
}
