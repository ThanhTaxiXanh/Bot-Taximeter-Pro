import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Dữ liệu POI giả lập; không biểu diễn khoảng cách hoặc địa chỉ đo thực tế.
class MockPlace {
  const MockPlace(this.name, this.address, this.distance, this.category, this.icon);
  final String name;
  final String address;
  final String distance;
  final String category;
  final IconData icon;
}

const List<String> mockCategories = <String>[
  'Sân bay', 'Bến xe', 'Khách sạn', 'Bệnh viện', 'ATM', 'Ăn uống',
];

const List<MockPlace> mockPlaces = <MockPlace>[
  MockPlace('Sân bay quốc tế Nội Bài (HAN)',
      'Phú Minh, Sóc Sơn, Hà Nội', '26,4 km', 'Sân bay', Icons.flight),
  MockPlace('Khách sạn Mường Thanh Luxury Bắc Giang',
      'Ngô Quyền, Bắc Giang', '4,2 km', 'Khách sạn', Icons.hotel),
  MockPlace('Bệnh viện Đa khoa tỉnh Bắc Giang',
      'Đường Lê Lợi, Bắc Giang', '3,9 km', 'Bệnh viện', Icons.local_hospital),
  MockPlace('Bến xe Bắc Giang',
      'Đường Nguyễn Văn Cừ, Bắc Giang', '4,0 km', 'Bến xe', Icons.directions_bus),
  MockPlace('ATM Vietcombank Bắc Giang',
      'Trung tâm Bắc Giang', '2,5 km', 'ATM', Icons.account_balance),
  MockPlace('Nhà hàng Hương Quê',
      'Trung tâm Bắc Giang', '1,8 km', 'Ăn uống', Icons.restaurant),
];

/// Bản đồ tuyến đường vẽ trên Canvas, không dùng SDK Maps/Static Maps.
class MockRouteMap extends StatelessWidget {
  const MockRouteMap({super.key, required this.selectedRoute});
  final int selectedRoute;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(
      height: 198,
      width: double.infinity,
      child: Stack(children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: MockRoutePainter(selectedRoute: selectedRoute),
          ),
        ),
        Positioned(
          top: 10, left: 10,
          child: _Bubble(
            label: selectedRoute == 0 ? '10 phút · 3,8 km'
                : selectedRoute == 1 ? '13 phút · 4,1 km'
                : '12 phút · 4,3 km',
            selected: true,
          ),
        ),
        const Positioned(
          right: 8, bottom: 10,
          child: _Bubble(label: 'BẢN ĐỒ MẪU'),
        ),
      ]),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.label, this.selected = false});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFF1057B7) : AppColors.backgroundStart,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(label, style: const TextStyle(
      color: AppColors.white, fontSize: 11,
      fontWeight: FontWeight.bold,
    )),
  );
}

class MockRoutePainter extends CustomPainter {
  const MockRoutePainter({required this.selectedRoute});
  final int selectedRoute;

  static const List<List<Offset>> routes = <List<Offset>>[
    <Offset>[
      Offset(.12, .78), Offset(.28, .74), Offset(.31, .50),
      Offset(.62, .50), Offset(.63, .26), Offset(.85, .24),
    ],
    <Offset>[
      Offset(.12, .78), Offset(.15, .37), Offset(.46, .33),
      Offset(.59, .18), Offset(.85, .24),
    ],
    <Offset>[
      Offset(.12, .78), Offset(.37, .84), Offset(.50, .67),
      Offset(.75, .63), Offset(.85, .24),
    ],
  ];

  Path _route(List<Offset> points, Size size) {
    final path = Path()
      ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFFBECAD8), Color(0xFFE5EDF1)],
      ).createShader(rect));
    final road = Paint()
      ..color = const Color(0xFFFCFCFD)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 7; i++) {
      final x = size.width * i / 7;
      canvas.drawLine(Offset(x, 0), Offset(x + 18, size.height), road);
    }
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 8), road);
    }
    for (var i = 0; i < routes.length; i++) {
      if (i == selectedRoute) continue;
      canvas.drawPath(_route(routes[i], size), Paint()
        ..color = const Color(0xFF8E9FB3)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke);
    }
    canvas.drawPath(_route(routes[selectedRoute], size), Paint()
      ..color = const Color(0xFF1064EC)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke);
    final start = routes[selectedRoute].first;
    final end = routes[selectedRoute].last;
    for (final p in <Offset>[start, end]) {
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        8, Paint()..color = p == start ? AppColors.cyan : AppColors.poi,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MockRoutePainter oldDelegate) =>
      oldDelegate.selectedRoute != selectedRoute;
}
