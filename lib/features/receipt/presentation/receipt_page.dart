import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import 'receipt_widgets.dart';

/// Màn biên lai theo ảnh mẫu. Không xác nhận thanh toán thật.
class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key, this.snapshot = const <String, String>{}});
  final Map<String, String> snapshot;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _transfer = true;
  bool _is3D = true;
  String _bank = '';
  String _owner = '';
  String _account = '';

  bool get _recorded => widget.snapshot['isRecorded'] == 'true';

  String _field(String key, String fallback) =>
      widget.snapshot[key]?.trim().isNotEmpty == true
          ? widget.snapshot[key]!
          : (_recorded ? 'Chưa ghi nhận' : fallback);

  @override
  void initState() {
    super.initState();
    _loadBank();
  }

  Future<void> _loadBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _bank = prefs.getString('bank_name') ?? '';
        _owner = prefs.getString('bank_owner') ?? '';
        _account = prefs.getString('bank_account') ?? '';
        _transfer = prefs.getBool('default_transfer') ?? true;
      });
    } catch (_) {
      // Không để lỗi lưu cấu hình làm hỏng màn biên lai.
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );

  void _unsupported(String title) => _notice(
    '$title sẽ được triển khai ở Bước 13; chưa tạo tệp thật.',
  );

  Widget _receiptDetails() => GlassCard(
    selected: true,
    padding: const EdgeInsets.all(13),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Row(children: <Widget>[
          Icon(Icons.receipt_long, color: AppColors.cyan, size: 25),
          SizedBox(width: 8),
          Expanded(child: Text('Biên lai chuyến đi', style: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w800,
          ))),
        ]),
        const Divider(color: AppColors.border),
        ReceiptInfoRow(
          icon: Icons.person, label: 'Khách hàng',
          value: _field('customer', 'Nguyễn Văn Hưng (mẫu)'),
          onTap: () => _notice('Chưa có số điện thoại khách để gọi.'),
        ),
        ReceiptInfoRow(
          icon: Icons.location_on, label: 'Điểm đón',
          value: _field('pickup', 'Đường Trần Nhân Vũ, Bắc Giang (mẫu)'),
        ),
        ReceiptInfoRow(
          icon: Icons.flag, label: 'Điểm trả',
          value: _field('dropoff', 'Khách sạn Hương Giang (mẫu)'),
        ),
        ReceiptInfoRow(
          icon: Icons.play_circle, label: 'Bắt đầu',
          value: _field('started', '09:42 - 26/01/2025 (mẫu)'),
        ),
        ReceiptInfoRow(
          icon: Icons.flag_circle, label: 'Kết thúc',
          value: _field('finished', '10:08 - 26/01/2025 (mẫu)'),
        ),
        ReceiptInfoRow(
          icon: Icons.route, label: 'Quãng đường',
          value: _field('distance', '8,4 km'),
        ),
        ReceiptInfoRow(
          icon: Icons.hourglass_empty, label: 'Tiền chờ',
          value: _field('waitFee', '7.000 đ (5 phút) · mẫu'),
        ),
        ReceiptInfoRow(
          icon: Icons.toll, label: 'Trạm thu phí',
          value: _field('toll', '0 đ'),
        ),
        if (widget.snapshot.containsKey('duration'))
          ReceiptInfoRow(
            icon: Icons.timer, label: 'Thời gian chuyến',
            value: _field('duration', '00:00'),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cyan),
          ),
          child: Row(children: <Widget>[
            const Icon(Icons.payments_outlined,
                color: AppColors.cyan, size: 26),
            const SizedBox(width: 8),
            const Expanded(child: Text('Tổng cước', style: TextStyle(
              color: AppColors.white, fontWeight: FontWeight.w800,
              fontSize: 17,
            ))),
            Flexible(child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(_field('fare', '72.000 đ'),
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 25, fontWeight: FontWeight.w900,
                  )),
            )),
          ]),
        ),
      ],
    ),
  );

  Widget _paymentSelector() => GlassCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Row(children: <Widget>[
          Icon(Icons.account_balance_wallet_outlined,
              color: AppColors.cyan),
          SizedBox(width: 8),
          Expanded(child: Text('Phương thức thanh toán', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold,
          ))),
        ]),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          Expanded(child: NeonButton(
            label: 'Tiền Mặt',
            icon: _transfer ? Icons.money : Icons.check_circle,
            primary: !_transfer,
            onPressed: () => setState(() => _transfer = false),
          )),
          const SizedBox(width: 8),
          Expanded(child: NeonButton(
            label: 'Chuyển Khoản',
            icon: _transfer ? Icons.check_circle : Icons.swap_horiz,
            primary: _transfer,
            onPressed: () => setState(() => _transfer = true),
          )),
        ]),
        const SizedBox(height: 5),
        const Text('Chỉ chọn hình thức dự kiến, không xác nhận đã thu tiền.',
            style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    ),
  );

  Widget _buttons() => Row(children: <Widget>[
    Expanded(child: NeonButton(
      label: 'In biên lai', icon: Icons.print, primary: false,
      onPressed: () => _unsupported('In biên lai'),
    )),
    const SizedBox(width: 6),
    Expanded(child: NeonButton(
      label: 'Chia sẻ', icon: Icons.share, primary: false,
      onPressed: () => _unsupported('Chia sẻ'),
    )),
    const SizedBox(width: 6),
    Expanded(child: NeonButton(
      label: 'Xuất PDF', icon: Icons.picture_as_pdf, primary: false,
      onPressed: () => _unsupported('Xuất PDF'),
    )),
  ]);

  @override
  Widget build(BuildContext context) => AppShell(
    title: 'Chi tiết chuyến đi', showBack: true,
    onBack: () => context.canPop()
        ? context.pop() : context.go(AppRouter.home),
    helpText: 'Xem lộ trình cuốc xe, biên lai chi tiết, '
        'trạng thái thanh toán và mã QR thanh toán.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(_recorded
            ? 'BIÊN LAI CƯỚC GPS THAM KHẢO · CHƯA KIỂM ĐỊNH'
            : 'DỮ LIỆU MẪU · KHÔNG PHẢI HÓA ĐƠN',
            style: const TextStyle(
              color: AppColors.danger, fontSize: 11,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 8),
        ReceiptRouteCard(
          tripId: _field('id', 'TTX-250126-0147'),
          is3D: _is3D,
          on3D: () => setState(() => _is3D = true),
          on2D: () => setState(() => _is3D = false),
          onRecenter: () => _notice('Bản đồ mẫu, chưa có GPS thật.'),
        ),
        const SizedBox(height: 10),
        _receiptDetails(),
        const SizedBox(height: 10),
        _paymentSelector(),
        if (_transfer) ...<Widget>[
          const SizedBox(height: 10),
          DemoVietQrPanel(bank: _bank, owner: _owner, account: _account),
        ],
        const SizedBox(height: 12),
        _buttons(),
        const SizedBox(height: 8),
      ],
    ),
  );
}
