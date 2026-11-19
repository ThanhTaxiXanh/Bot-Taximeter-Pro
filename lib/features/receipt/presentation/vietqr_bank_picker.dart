import 'package:flutter/material.dart';

import '../../map_tracking/data/gps_tracker.dart';
import '../data/vietqr_bank_repository.dart';

/// Người dùng chọn ngân hàng; chỉ điền tên/BIN vào form, không tự lưu.
class VietQrBankPicker extends StatefulWidget {
  const VietQrBankPicker({
    super.key, required this.onSelected, this.repository,
  });
  final ValueChanged<VietQrBank> onSelected;
  final VietQrBankRepository? repository;
  @override
  State<VietQrBankPicker> createState() => _VietQrBankPickerState();
}

class _VietQrBankPickerState extends State<VietQrBankPicker> {
  late final VietQrBankRepository _repo =
      widget.repository ?? VietQrBankRepository();
  List<VietQrBank> _banks = <VietQrBank>[];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final banks = await _repo.offline();
      if (mounted) setState(() => _banks = banks);
    } catch (_) {
      if (mounted) setState(() =>
          _error = 'Không đọc được danh sách ngân hàng dự phòng.');
    }
  }

  Future<void> _refresh() async {
    if (_busy || GpsTracker.useMock) return;
    setState(() { _busy = true; _error = null; });
    try {
      final banks = await _repo.refresh();
      if (mounted) setState(() => _banks = banks);
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Đã cập nhật danh sách VietQR.')),
      );
    } catch (_) {
      if (mounted) setState(() => _error =
          'Không làm mới được. Danh sách cũ vẫn được giữ.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choose() async {
    if (_banks.isEmpty) return;
    var query = '';
    final selected = await showDialog<VietQrBank>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) {
          final matches = _banks.where((bank) {
            final key = query.toLowerCase();
            return bank.shortName.toLowerCase().contains(key) ||
                bank.name.toLowerCase().contains(key) ||
                bank.bin.contains(key);
          }).toList();
          return AlertDialog(
            title: const Text('Chọn ngân hàng VietQR'),
            content: SizedBox(
              width: 360, height: 390,
              child: Column(children: <Widget>[
                TextField(
                  key: const Key('search_vietqr_bank'),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Tìm tên ngân hàng hoặc BIN'),
                  onChanged: (value) => update(() => query = value),
                ),
                const SizedBox(height: 8),
                Expanded(child: ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final bank = matches[index];
                    return ListTile(
                      dense: true,
                      title: Text(bank.shortName),
                      subtitle: Text('BIN ' + bank.bin),
                      onTap: () => Navigator.pop(dialog, bank),
                    );
                  },
                )),
              ]),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Hủy'),
              ),
            ],
          );
        },
      ),
    );
    if (selected != null && mounted) widget.onSelected(selected);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      OutlinedButton.icon(
        key: const Key('choose_vietqr_bank'),
        icon: const Icon(Icons.account_balance),
        onPressed: _banks.isEmpty ? null : _choose,
        label: Text(_banks.isEmpty ? 'Đang tải ngân hàng…' :
            'Chọn ngân hàng trong danh sách (' +
                _banks.length.toString() + ')'),
      ),
      if (!GpsTracker.useMock) TextButton.icon(
        key: const Key('refresh_vietqr_banks'),
        onPressed: _busy ? null : _refresh,
        icon: const Icon(Icons.refresh),
        label: const Text('Làm mới danh sách từ VietQR'),
      ),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Colors.redAccent,
            fontSize: 12)),
      const Text('Danh sách cache/seed chỉ hỗ trợ chọn mã BIN. '
          'Kiểm tra số tài khoản và tên người nhận trong ứng dụng '
          'ngân hàng trước khi sử dụng VietQR.',
          style: TextStyle(fontSize: 11)),
    ],
  );
}
