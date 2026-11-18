import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/app_shell.dart';
import '../../../shared/glass_widgets.dart';
import 'home_map_mock.dart';
import 'mock_travel_data.dart';

/// Tìm kiếm POI bằng dữ liệu mẫu, chưa kết nối mạng.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  String? _category;
  int _selected = 0;
  bool _is3D = true;
  bool _traffic = false;
  final List<int> _recent = <int>[0, 1, 2, 3];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<int> get _matches => <int>[
    for (var i = 0; i < mockPlaces.length; i++)
      if ((_category == null || mockPlaces[i].category == _category) &&
          mockPlaces[i].name.toLowerCase().contains(_query.trim().toLowerCase()))
        i,
  ];

  void _notice(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  void _select(int index) => setState(() {
    _selected = index;
    _recent.remove(index);
    _recent.insert(0, index);
  });

  void _pick(bool start) => context.push(AppRouter.route, extra: <String, String>{
    start ? 'start' : 'end': mockPlaces[_selected].name,
  });

  Widget _searchBar() => TextField(
    controller: _controller,
    onChanged: (value) => setState(() => _query = value),
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Tìm địa chỉ, địa điểm, POI...',
      prefixIcon: const Icon(Icons.search, color: AppColors.cyan),
      suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        if (_query.isNotEmpty)
          IconButton(
            tooltip: 'Xóa tìm kiếm',
            icon: const Icon(Icons.cancel_outlined),
            onPressed: () {
              _controller.clear();
              setState(() => _query = '');
            },
          ),
        const SizedBox(height: 22, child: VerticalDivider(color: AppColors.border)),
        IconButton(
          tooltip: 'Tìm bằng giọng nói',
          icon: const Icon(Icons.mic, color: AppColors.cyan),
          onPressed: () => _notice('Nhập giọng nói sẽ có ở bước sau.'),
        ),
      ]),
    ),
  );

  Widget _filters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: <Widget>[
      for (final value in mockCategories)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(value),
            selected: _category == value,
            selectedColor: const Color(0xFF136C81),
            side: const BorderSide(color: AppColors.border),
            onSelected: (active) => setState(
              () => _category = active ? value : null,
            ),
          ),
        ),
    ]),
  );

  Widget _map() => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: SizedBox(height: 195, child: Stack(children: <Widget>[
      Positioned.fill(child: CustomPaint(
        painter: HomeMockMapPainter(
          is3D: _is3D, isDark: false, traffic: _traffic,
        ),
      )),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        const Icon(Icons.location_pin, color: AppColors.poi, size: 31),
        Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1655A6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(mockPlaces[_selected].name,
            maxLines: 2, textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold,
            )),
        ),
      ])),
      Positioned(top: 3, right: 3, child: SizedBox(
        width: 60, height: 188,
        child: FittedBox(
          fit: BoxFit.scaleDown, alignment: Alignment.topCenter,
          child: MapControlButtons(
            is3D: _is3D, trafficEnabled: _traffic, showDayNight: false,
            on3D: () => setState(() => _is3D = true),
            on2D: () => setState(() => _is3D = false),
            onTraffic: () => setState(() => _traffic = !_traffic),
            onRecenter: () => _notice('Đây là bản đồ mẫu, chưa dùng GPS.'),
          ),
        ),
      )),
      const Positioned(left: 8, bottom: 8,
        child: Text('BẢN ĐỒ MẪU',
            style: TextStyle(color: AppColors.navyInk, fontSize: 10))),
    ])),
  );

  Widget _selectedCard() {
    final place = mockPlaces[_selected];
    return GlassCard(selected: true, child: Column(children: <Widget>[
      Row(children: <Widget>[
        Icon(place.icon, color: AppColors.cyan, size: 26),
        const SizedBox(width: 9),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(place.name, maxLines: 2,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(place.address, maxLines: 2,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        )),
        Text(place.distance,
            style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
      ]),
      const SizedBox(height: 10),
      Row(children: <Widget>[
        Expanded(child: NeonButton(
          label: 'Chọn điểm đi', icon: Icons.near_me, onPressed: () => _pick(true),
        )),
        const SizedBox(width: 6),
        Expanded(child: NeonButton(
          label: 'Chọn điểm đến', icon: Icons.flag,
          primary: false, onPressed: () => _pick(false),
        )),
      ]),
    ]));
  }

  Widget _placeItem(int i) {
    final place = mockPlaces[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: GlassCard(
        selected: i == _selected,
        padding: const EdgeInsets.all(11),
        onTap: () => _select(i),
        child: Row(children: <Widget>[
          Icon(place.icon, color: AppColors.cyan),
          const SizedBox(width: 9),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(place.name, maxLines: 2,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(place.address, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          )),
          const SizedBox(width: 5),
          Text(place.distance,
              style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _results() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Row(children: <Widget>[
        const Expanded(child: Text('Kết quả tìm kiếm',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        TextButton(
          onPressed: () => _notice('Hiện có ${_matches.length} kết quả mẫu.'),
          child: Text('Xem thêm (${_matches.length})'),
        ),
      ]),
      if (_matches.isEmpty)
        const GlassCard(child: Text('Không có kết quả trong dữ liệu mẫu.')),
      for (final index in _matches) _placeItem(index),
    ],
  );

  Widget _history() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Row(children: <Widget>[
        const Expanded(child: Text('Tìm kiếm gần đây',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
        TextButton.icon(
          label: const Text('Xóa tất cả'),
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () => setState(_recent.clear),
        ),
      ]),
      Wrap(spacing: 5, children: <Widget>[
        for (final index in _recent)
          InputChip(
            label: Text(mockPlaces[index].category),
            avatar: const Icon(Icons.history, size: 18),
            onPressed: () => _select(index),
            onDeleted: () => setState(() => _recent.remove(index)),
          ),
      ]),
    ],
  );

  @override
  Widget build(BuildContext context) => AppShell(
    showBack: true,
    onBack: () => context.canPop()
        ? context.pop() : context.go(AppRouter.home),
    helpText: 'Tìm nhanh địa chỉ, tìm POI, tìm bằng giọng nói, chọn điểm đi/đến.',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _searchBar(),
        const SizedBox(height: 7),
        _filters(),
        const SizedBox(height: 8),
        _map(),
        const SizedBox(height: 9),
        _selectedCard(),
        const SizedBox(height: 9),
        _results(),
        const SizedBox(height: 10),
        _history(),
      ],
    ),
  );
}
