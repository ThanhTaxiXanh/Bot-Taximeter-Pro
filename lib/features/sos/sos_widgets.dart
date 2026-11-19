import 'package:flutter/material.dart';

import '../settings/presentation/settings_widgets.dart';
import 'sos_service.dart';

/// Hai hành động riêng; mỗi hành động phải được tài xế xác nhận lần nữa.
abstract final class SosDialog {
  static Future<void> show(BuildContext context, {SosService? service}) async {
    final sos = service ?? SosService();
    String phone;
    try {
      phone = await sos.configuredPhone();
    } catch (_) {
      phone = SosService.defaultPhone;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('SOS · Hỗ trợ khẩn cấp'),
        content: Text(
          'Số đã cấu hình: $phone.\n'
          'Chọn gọi điện hoặc chia sẻ vị trí GPS. '
          'Mỗi hành động cần xác nhận; ứng dụng không tự gọi hoặc gửi tin.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Đóng'),
          ),
          OutlinedButton.icon(
            key: const Key('sos_call'),
            onPressed: () => _call(dialog, sos, phone),
            icon: const Icon(Icons.call_outlined),
            label: Text('Gọi $phone'),
          ),
          FilledButton.icon(
            key: const Key('sos_share'),
            onPressed: () => _share(dialog, sos),
            icon: const Icon(Icons.share_location),
            label: const Text('Chia sẻ vị trí'),
          ),
        ],
      ),
    );
  }

  static Future<bool> _confirm(BuildContext parent,
      {required String title, required String message,
      required String proceed, required String key}) async {
    final result = await showDialog<bool>(
      context: parent,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            key: const Key('sos_cancel_action'),
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: Key(key),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(proceed),
          ),
        ],
      ),
    );
    return result == true;
  }

  static void _notice(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<void> _call(
      BuildContext dialog, SosService service, String phone) async {
    final ok = await _confirm(
      dialog,
      title: 'Mở trình gọi điện?',
      message: 'Mở ứng dụng điện thoại với số $phone. '
          'Bạn vẫn phải bấm gọi trong ứng dụng điện thoại.',
      proceed: 'Mở trình gọi điện',
      key: 'sos_confirm_call',
    );
    if (!ok || !dialog.mounted) return;
    try {
      final opened = await service.openPhoneApp(phone);
      if (!opened && dialog.mounted) {
        _notice(dialog, 'Không mở được ứng dụng điện thoại.');
      }
    } catch (_) {
      if (dialog.mounted) {
        _notice(dialog, 'Không mở được trình gọi điện. '
            'Bạn có thể quay số thủ công.');
      }
    }
  }

  static Future<void> _share(
      BuildContext dialog, SosService service) async {
    if (service.locationMessage() == null) {
      _notice(dialog, 'Chưa có vị trí GPS mới và đủ chính xác để chia sẻ.');
      return;
    }
    final ok = await _confirm(
      dialog,
      title: 'Chia sẻ vị trí SOS?',
      message: 'Mở bảng chia sẻ vị trí GPS hiện tại để bạn '
          'tự chọn ứng dụng và người nhận. Không tự gửi tin.',
      proceed: 'Mở bảng chia sẻ',
      key: 'sos_confirm_share',
    );
    if (!ok || !dialog.mounted) return;
    final message = service.locationMessage();
    if (message == null) {
      _notice(dialog, 'GPS không còn đủ tin cậy. Hãy thử lại.');
      return;
    }
    try {
      await service.openPositionShare(message);
    } catch (_) {
      if (dialog.mounted) {
        _notice(dialog, 'Không thể mở bảng chia sẻ vị trí.');
      }
    }
  }
}

/// Lưu số SOS riêng; không ảnh hưởng nút Lưu các thiết lập khác.
class SosSettingsCard extends StatefulWidget {
  const SosSettingsCard({super.key});
  @override
  State<SosSettingsCard> createState() => _SosSettingsCardState();
}

class _SosSettingsCardState extends State<SosSettingsCard> {
  final _phone = TextEditingController(text: SosService.defaultPhone);
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await SosService().configuredPhone();
      if (mounted) _phone.text = value;
    } catch (_) {
      if (mounted) _error = 'Không đọc được số đã lưu. Đang dùng 113.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      await SosService().savePhone(_phone.text);
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Đã lưu số SOS trên thiết bị.')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsSection(
    title: 'SOS khẩn cấp', icon: Icons.sos,
    children: <Widget>[
      const Text('Số mặc định 113 (Công an). Có thể đổi sang số '
          'liên hệ khẩn cấp phù hợp. Chỉ mở trình gọi điện khi '
          'tài xế chủ động xác nhận.',
          style: TextStyle(fontSize: 12)),
      SettingsField(
        label: 'Số điện thoại SOS', controller: _phone,
        keyboardType: TextInputType.phone,
      ),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) Text(_error!,
          style: const TextStyle(color: Colors.redAccent)),
      Align(alignment: Alignment.centerRight,
        child: FilledButton.icon(
          key: const Key('save_sos_phone'),
          onPressed: _saving || _loading ? null : _save,
          icon: const Icon(Icons.save),
          label: const Text('Lưu số SOS'),
        ),
      ),
      const Text('Chia sẻ vị trí chỉ dùng GPS đủ tin cậy '
          'và yêu cầu chọn người nhận; không tự gửi hoặc gọi.',
          style: TextStyle(fontSize: 11)),
    ],
  );
}
