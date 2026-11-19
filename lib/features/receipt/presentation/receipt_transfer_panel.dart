import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';
import '../data/vietqr_transfer_payload.dart';
import 'receipt_widgets.dart';

/// Mã chuyển khoản chỉ hiển thị sau khi tài xế chủ động yêu cầu.
class ReceiptTransferPanel extends StatefulWidget {
  const ReceiptTransferPanel({
    super.key, required this.snapshot, required this.bank,
    required this.owner, required this.account,
  });

  final Map<String, String> snapshot;
  final String bank, owner, account;

  @override
  State<ReceiptTransferPanel> createState() => _ReceiptTransferPanelState();
}

class _ReceiptTransferPanelState extends State<ReceiptTransferPanel> {
  bool _ready = false, _enabled = false, _revealed = false;
  String _bin = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _enabled = prefs.getBool('vietqr_real_enabled') ?? false;
        _bin = prefs.getString('vietqr_bank_bin') ?? '';
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  void didUpdateWidget(covariant ReceiptTransferPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot['id'] != widget.snapshot['id'] ||
        oldWidget.account != widget.account) {
      _revealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.snapshot['isRecorded'] != 'true') {
      return DemoVietQrPanel(
        bank: widget.bank, owner: widget.owner, account: widget.account);
    }
    if (!_ready) return const LinearProgressIndicator();
    if (!_enabled) {
      return const GlassCard(child: Text(
        'VietQR chuyển khoản đang tắt. Có thể bật thủ công trong '
        'Cài đặt → Thanh toán. Không có mã chuyển tiền thật.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ));
    }

    String? payload, error;
    try {
      final amount = int.tryParse(widget.snapshot['amountVnd'] ?? '');
      if (amount == null) throw const FormatException('Thiếu tiền cước gốc');
      final note = VietQrTransferPayload.noteForTrip(
          widget.snapshot['id'] ?? '');
      payload = VietQrTransferPayload.encode(
        bankBin: _bin, account: widget.account,
        amountVnd: amount, note: note);
    } catch (_) {
      error = 'Cấu hình BIN/Số tài khoản hoặc số tiền chuyến không hợp lệ. '
          'Kiểm tra Cài đặt trước khi tạo QR.';
    }

    return GlassCard(padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('VIETQR · YÊU CẦU CHUYỂN KHOẢN',
            style: TextStyle(color: AppColors.cyan,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Có thể khởi tạo chuyển tiền thật từ ứng dụng ngân hàng. '
            'Chỉ dùng khi đã đối chiếu đúng biểu phí, tài khoản và số tiền.',
            style: TextStyle(color: AppColors.danger, fontSize: 12)),
          const SizedBox(height: 7),
          Text('Ngân hàng: ${widget.bank.isEmpty ? 'Chưa ghi' : widget.bank}'),
          Text('Người nhận dự kiến: ${widget.owner}'),
          Text('BIN: $_bin · Số tài khoản: ${widget.account}'),
          Text('Số tiền yêu cầu: ${widget.snapshot['fare'] ?? 'Không có'}'),
          const SizedBox(height: 8),
          if (error != null)
            Text(error, style: const TextStyle(
                color: AppColors.danger, fontSize: 12))
          else if (!_revealed)
            FilledButton.icon(
              key: const Key('show_live_vietqr'),
              onPressed: () => setState(() => _revealed = true),
              icon: const Icon(Icons.qr_code),
              label: const Text('Hiển thị QR chuyển khoản'),
            )
          else ...<Widget>[
            Center(child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: QrImageView(
                key: const Key('real_vietqr_qr'),
                data: payload!, version: QrVersions.auto,
                size: 220, errorCorrectionLevel: QrErrorCorrectLevel.M,
                backgroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
            )),
            TextButton(
              onPressed: () => setState(() => _revealed = false),
              child: const Text('Ẩn QR chuyển khoản'),
            ),
          ],
          const SizedBox(height: 8),
          const Text('Ứng dụng KHÔNG kiểm tra số dư hoặc xác nhận đã nhận tiền. '
            'Chỉ xác nhận giao dịch qua ứng dụng/ngân hàng của bạn. '
            'Đây không phải hóa đơn taxi đã kiểm định.',
            style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }
}
