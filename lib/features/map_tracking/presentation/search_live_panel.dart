import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/glass_widgets.dart';
import '../data/place_search_service.dart';

/// Tìm địa chỉ thật chỉ sau khi bấm nút. Tuyệt đối không autocomplete API.
class SearchLivePanel extends StatefulWidget {
  const SearchLivePanel({super.key, required this.query,
    required this.onPick, this.service});
  final String query;
  final void Function(LocatedPlace place, bool start) onPick;
  final NominatimPlaceService? service;

  @override
  State<SearchLivePanel> createState() => _SearchLivePanelState();
}

class _SearchLivePanelState extends State<SearchLivePanel> {
  late final NominatimPlaceService _service =
      widget.service ?? NominatimPlaceService.instance;
  List<LocatedPlace> _results = const [];
  LocatedPlace? _selected;
  bool _busy = false, _searched = false;
  String? _error;

  Future<void> _search() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _searched = false;
      _results = const [];
      _selected = null;
    });
    try {
      final results = await _service.search(widget.query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searched = true;
        if (results.isNotEmpty) _selected = results.first;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('Tra cứu địa chỉ thật',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(_service.configured
            ? 'Chỉ gửi yêu cầu khi bấm Tìm thật, không tự tìm theo từng ký tự.'
            : 'Chưa cấu hình máy chủ Nominatim được phép. Các mục bên dưới là mẫu.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(height: 6),
        FilledButton.icon(
          onPressed: !_service.configured || _busy ? null : _search,
          icon: const Icon(Icons.travel_explore),
          label: const Text('Tìm thật'),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) Text(_error!,
            style: const TextStyle(color: AppColors.danger)),
        if (_searched && _results.isEmpty)
          const Text('Không tìm thấy địa chỉ phù hợp.'),
        for (final place in _results)
          RadioListTile<LocatedPlace>(
            value: place,
            groupValue: _selected,
            onChanged: (value) => setState(() => _selected = value),
            title: Text(place.name, maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            dense: true,
          ),
        if (_selected != null) Row(children: <Widget>[
          Expanded(child: TextButton(
            onPressed: () => widget.onPick(_selected!, true),
            child: const Text('Chọn điểm đi'),
          )),
          Expanded(child: TextButton(
            onPressed: () => widget.onPick(_selected!, false),
            child: const Text('Chọn điểm đến'),
          )),
        ]),
        const Text('Dữ liệu: © OpenStreetMap contributors',
            style: TextStyle(color: AppColors.muted, fontSize: 10)),
      ],
    ),
  );
}
