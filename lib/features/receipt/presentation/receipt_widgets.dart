import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';
import '../../../shared/route_preview_painter.dart';

/// Thẻ lộ trình nhỏ, không tải tile Google Maps và không định vị GPS.
class ReceiptRouteCard extends StatelessWidget {
  const ReceiptRouteCard({
    super.key, required this.tripId, required this.is3D,
    required this.on3D, required this.on2D, required this.onRecenter,
  });
  final String tripId;
  final bool is3D;
  final VoidCallback on3D;
  final VoidCallback on2D;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(8),
    child: Column(children: <Widget>[
      Row(children: <Widget>[
        Expanded(child: Text('Mã chuyến: $tripId',
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold,
              color: AppColors.cyan,
            ))),
        const Icon(Icons.check_circle, color: AppColors.success, size: 17),
        const SizedBox(width: 4),
        const Text('Đã hoàn thành',
            style: TextStyle(fontSize: 11, color: AppColors.success)),
      ]),
      const SizedBox(height: 8),
      SizedBox(height: 175, child: Stack(children: <Widget>[
        const Positioned.fill(child: RoutePreview(height: 175)),
        const Positioned(
          left: 6, bottom: 8,
          child: _MapBadge(label: 'Điểm đón', icon: Icons.location_on),
        ),
        const Positioned(
          right: 66, top: 10,
          child: _MapBadge(label: 'Điểm trả', icon: Icons.flag),
        ),
        Positioned(
          right: 4, top: 4,
          child: SizedBox(
            width: 60, height: 165,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: MapControlButtons(
                is3D: is3D, trafficEnabled: false,
                showDayNight: false,
                on3D: on3D, on2D: on2D, onRecenter: onRecenter,
              ),
            ),
          ),
        ),
        const Positioned(
          top: 10, left: 6,
          child: Text('BẢN ĐỒ MẪU',
              style: TextStyle(
                fontSize: 10, color: AppColors.muted,
                fontWeight: FontWeight.w700,
              )),
        ),
      ])),
    ]),
  );
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.backgroundStart,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Icon(icon, size: 14, color: AppColors.cyan),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(
        color: AppColors.white, fontSize: 11,
      )),
    ]),
  );
}

/// Dòng dữ liệu biên lai, giữ chữ trong khung khi giá trị dài.
class ReceiptInfoRow extends StatelessWidget {
  const ReceiptInfoRow({
    super.key, required this.icon, required this.label,
    required this.value, this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: <Widget>[
      Icon(icon, color: AppColors.cyan, size: 18),
      const SizedBox(width: 9),
      SizedBox(width: 104, child: Text(label,
          style: const TextStyle(
            color: AppColors.muted, fontSize: 12,
          ))),
      Expanded(child: Text(value, maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white, fontSize: 12,
            fontWeight: FontWeight.w600,
          ))),
      if (onTap != null)
        IconButton(
          tooltip: 'Gọi khách (chưa khả dụng)',
          onPressed: onTap,
          icon: const Icon(Icons.phone_outlined, color: AppColors.cyan),
        ),
    ]),
  );
}

/// QR kỹ thuật mang chuỗi DEMO, KHÔNG phải payload EMVCo/VietQR.
class DemoVietQrPanel extends StatelessWidget {
  const DemoVietQrPanel({
    super.key, required this.bank, required this.owner,
    required this.account,
  });
  final String bank;
  final String owner;
  final String account;

  @override
  Widget build(BuildContext context) => GlassCard(
    selected: true,
    padding: const EdgeInsets.all(12),
    child: Column(children: <Widget>[
      Row(children: <Widget>[
        const Expanded(child: Text('VietQR · BẢN MẪU',
            style: TextStyle(
              color: AppColors.cyan, fontWeight: FontWeight.w800,
            ))),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.danger),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(5),
          child: const Text('KHÔNG THANH TOÁN',
              style: TextStyle(color: AppColors.danger, fontSize: 9)),
        ),
      ]),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Quét mã để thanh toán',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                )),
            const Text('(chưa khả dụng trong bản mẫu)',
                style: TextStyle(color: AppColors.danger, fontSize: 11)),
            const SizedBox(height: 9),
            Text('Ngân hàng: ${bank.isEmpty ? 'Chưa cấu hình' : bank}'),
            Text('Chủ TK: ${owner.isEmpty ? 'Chưa cấu hình' : owner}'),
            Text('Số TK: ${account.isEmpty ? 'Chưa cấu hình' : account}'),
          ],
        );
        final qr = Column(children: <Widget>[
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(alignment: Alignment.center, children: <Widget>[
              QrImageView(
                key: const Key('demo_qr'),
                data: 'BOT-TAXIMETER-PRO|DEMO|NOT-A-PAYMENT',
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                size: 128,
                backgroundColor: AppColors.white,
                padding: EdgeInsets.zero,
              ),
              const CircleAvatar(
                radius: 13, backgroundColor: AppColors.white,
                child: Text('TTX', style: TextStyle(
                  color: AppColors.navyInk, fontSize: 8,
                  fontWeight: FontWeight.bold,
                )),
              ),
            ]),
          ),
          const SizedBox(height: 5),
          Image.asset('assets/images/logo.png', width:40, height:40,
              semanticLabel: 'Logo mẫu TTX'),
        ]);
        return compact
            ? Column(children: <Widget>[
                details, const SizedBox(height: 12), qr,
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: details),
                  const SizedBox(width: 8),
                  qr,
                ]);
      }),
      const SizedBox(height: 8),
      const Text('Mã này chỉ chứa chuỗi DEMO, không chuyển tiền.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 11)),
    ]),
  );
}
