import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../map_tracking/data/gps_tracker.dart';
import 'road_context_provider.dart';
import 'speed_limit_engine.dart';
import 'speed_rules.dart';

/// Biển GPS/ngữ cảnh, chỉ dùng trên máy thật. CI giữ giao diện mẫu cũ.
/// Không tự coi dữ liệu OSM là biển báo có hiệu lực.
class RoadSpeedPanel extends StatefulWidget {
  const RoadSpeedPanel({super.key, this.controller});
  final RoadSpeedController? controller;
  @override
  State<RoadSpeedPanel> createState() => _RoadSpeedPanelState();
}

class _RoadSpeedPanelState extends State<RoadSpeedPanel> {
  late final RoadSpeedController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? RoadSpeedController.instance;
    _controller.load();
  }

  String _source(SpeedLimitSource source) => switch (source) {
    SpeedLimitSource.manual => 'TÀI XẾ NHẬP BIỂN',
    SpeedLimitSource.posted => 'OSM THAM KHẢO',
    SpeedLimitSource.rule => 'QUY TẮC THAM KHẢO',
    SpeedLimitSource.ruleGuess => 'ƯỚC TÍNH · CHƯA XÁC MINH',
    SpeedLimitSource.unknown => 'GIỚI HẠN CHƯA RÕ',
  };

  Future<void> _settings() async {
    var area = _controller.area;
    var way = _controller.carriageway;
    var manual = _controller.manualKmh?.toString() ?? '';
    var persistent = _controller.untilChanged;
    var endpoint = _controller.overpassUrl;
    String? error;
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => SafeArea(child: Padding(
          padding: EdgeInsets.fromLTRB(
            14, 6, 14, 16 + MediaQuery.viewInsetsOf(sheet).bottom),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Giới hạn tốc độ · nguồn cần xác minh',
                  style: TextStyle(fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Quan sát biển thực tế trên đường. OSM chỉ để '
                  'tham khảo; không xác nhận giới hạn pháp lý.',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              DropdownButtonFormField<AreaType>(
                key: const Key('speed_area'),
                initialValue: area, isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Khu vực bạn đã kiểm tra'),
                items: const <DropdownMenuItem<AreaType>>[
                  DropdownMenuItem(value: AreaType.unknown,
                      child: Text('Chưa rõ')),
                  DropdownMenuItem(value: AreaType.populated,
                      child: Text('Trong khu đông dân cư')),
                  DropdownMenuItem(value: AreaType.outsidePopulated,
                      child: Text('Ngoài khu đông dân cư')),
                  DropdownMenuItem(value: AreaType.motorway,
                      child: Text('Cao tốc')),
                ],
                onChanged: (v) => update(() => area = v ?? AreaType.unknown),
              ),
              const SizedBox(height: 7),
              DropdownButtonFormField<Carriageway>(
                key: const Key('speed_way'),
                initialValue: way, isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Kiểu đường bạn đã kiểm tra'),
                items: const <DropdownMenuItem<Carriageway>>[
                  DropdownMenuItem(value: Carriageway.unknown,
                      child: Text('Chưa rõ')),
                  DropdownMenuItem(
                    value: Carriageway.dividedOrMultilaneOneWay,
                    child: Text('Đường đôi / một chiều ≥2 làn')),
                  DropdownMenuItem(
                    value: Carriageway.twoWayOrSingleLaneOneWay,
                    child: Text('Hai chiều / một chiều 1 làn')),
                ],
                onChanged: (v) => update(() => way = v ?? Carriageway.unknown),
              ),
              const SizedBox(height: 7),
              TextFormField(
                key: ValueKey<String>('speed_manual_' + manual),
                initialValue: manual,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tốc độ trên biển thật (km/h)',
                  hintText: 'Để trống để dùng ngữ cảnh / --',
                ),
                onChanged: (v) => manual = v,
              ),
              const SizedBox(height: 7),
              Wrap(spacing: 5, runSpacing: 3, children: <Widget>[
                for (final speed in <int>[40, 50, 60, 70, 80, 90, 100, 120])
                  ActionChip(
                    label: Text('$speed'),
                    onPressed: () => update(() => manual = speed.toString()),
                  ),
              ]),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Giữ đến khi tôi đổi'),
                subtitle: const Text(
                    'Tắt: chỉ lưu cho đoạn ~200 m, yêu cầu GPS tốt'),
                value: persistent,
                onChanged: (v) => update(() => persistent = v),
              ),
              TextFormField(
                initialValue: endpoint,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Overpass HTTPS được phép (tùy chọn)',
                  hintText: 'https://máy-chủ-của-bạn/api/interpreter',
                ),
                onChanged: (v) => endpoint = v,
              ),
              const SizedBox(height: 7),
              if (error != null)
                Text(error!, style: const TextStyle(color: AppColors.danger)),
              Row(children: <Widget>[
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheet),
                  child: const Text('Hủy'),
                )),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(
                  key: const Key('save_speed_context'),
                  onPressed: () async {
                    final limit = manual.trim().isEmpty
                        ? null : int.tryParse(manual.trim());
                    if (manual.trim().isNotEmpty && limit == null) {
                      update(() => error = 'Biển phải là số nguyên.');
                      return;
                    }
                    try {
                      await _controller.configure(
                        selectedArea: area, selectedWay: way,
                        limit: limit, persistent: persistent,
                        url: endpoint,
                      );
                      if (sheet.mounted) Navigator.pop(sheet);
                    } catch (e) {
                      if (sheet.mounted) {
                        update(() => error = e.toString());
                      }
                    }
                  },
                  child: const Text('Lưu giới hạn'),
                )),
              ]),
              if (!GpsTracker.useMock && endpoint.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  icon: const Icon(Icons.travel_explore),
                  label: const Text('Tra cứu đường OSM (tham khảo)'),
                  onPressed: () async {
                    try {
                      await _controller.configure(
                        selectedArea: area, selectedWay: way,
                        limit: manual.trim().isEmpty ? null :
                            int.tryParse(manual.trim()),
                        persistent: persistent, url: endpoint);
                      await _controller.lookupRoad();
                      if (sheet.mounted) Navigator.pop(sheet);
                    } catch (e) {
                      if (sheet.mounted) {
                        update(() => error = e.toString());
                      }
                    }
                  },
                ),
              ],
            ],
          )),
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final legal = _controller.result;
      final speed = GpsTracker.instance.fix?.speedKmh.round() ?? 0;
      final alert = _controller.warning &&
          GpsTracker.instance.hasGoodFix;
      return Container(
        key: const Key('legal_speed_panel'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xE90A2346),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: alert
              ? AppColors.danger : AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text('$speed', style: const TextStyle(
                fontSize: 31, color: Colors.white,
                fontWeight: FontWeight.bold)),
              const Text('km/h', style: TextStyle(fontSize: 10)),
            ]),
            const SizedBox(width: 8),
            InkWell(
              key: const Key('legal_speed_open'),
              onTap: _settings, customBorder: const CircleBorder(),
              child: Container(
                width: 49, height: 49,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.danger, width: 4)),
                child: Text(legal.displayLabel, style: const TextStyle(
                  color: AppColors.navyInk, fontSize: 17,
                  fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
          Text(alert ? 'VƯỢT NGƯỠNG ĐÃ NHẬP' : _source(legal.source),
            style: TextStyle(
              color: alert ? AppColors.danger : AppColors.muted,
              fontSize: 8, fontWeight: FontWeight.bold)),
        ]),
      );
    },
  );
}
