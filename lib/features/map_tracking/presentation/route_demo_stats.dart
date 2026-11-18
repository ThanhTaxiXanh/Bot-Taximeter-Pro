import 'package:flutter/material.dart';

import '../../../shared/glass_widgets.dart';

/// Giữ nguyên số liệu mẫu chỉ cho CI và khi chưa có dịch vụ định tuyến.
class RouteDemoStats extends StatelessWidget {
  const RouteDemoStats({super.key, required this.index});
  final int index;

  static const etas = <String>['10 phút', '13 phút', '12 phút'];
  static const distances = <String>['3,8 km', '4,1 km', '4,3 km'];
  static const fares = <String>['≈ 72.000 đ', '≈ 78.000 đ', '≈ 80.000 đ'];

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2, childAspectRatio: 1.0,
    crossAxisSpacing: 7, mainAxisSpacing: 7,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: <Widget>[
      StatCard(label: 'ETA', value: etas[index], icon: Icons.schedule),
      StatCard(label: 'Quãng đường', value: distances[index],
          icon: Icons.route),
      StatCard(label: 'Cước ước tính', value: fares[index],
          icon: Icons.payments_outlined),
      const StatCard(label: 'Phí BOT', value: '0 đ', icon: Icons.toll),
    ],
  );
}
