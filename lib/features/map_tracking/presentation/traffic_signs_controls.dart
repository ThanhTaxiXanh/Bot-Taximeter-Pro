import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/gps_tracker.dart';
import '../data/imported_road_signs.dart';

/// Chọn CSV trên máy, hiển thị tối đa 32 biển trong viewport hiện hành.
class TrafficSignsControls extends StatefulWidget {
  const TrafficSignsControls({super.key, required this.selected,
    required this.onSelected, required this.onMarkersChanged});
  final bool selected;
  final ValueChanged<bool> onSelected;
  final ValueChanged<Set<Marker>> onMarkersChanged;
  @override
  TrafficSignsControlsState createState() => TrafficSignsControlsState();
}

class TrafficSignsControlsState extends State<TrafficSignsControls> {
  LatLngBounds? _bounds;
  int _generation = 0;
  static const _csv = XTypeGroup(
    label: 'Dữ liệu biển báo CSV',
    extensions: <String>['csv'],
    mimeTypes: <String>['text/csv', 'text/plain'],
  );

  @override
  void initState() {
    super.initState();
    if (!GpsTracker.useMock) {
      ImportedRoadSigns.instance.loadCount().catchError((Object _) {});
    }
  }

  @override
  void didUpdateWidget(covariant TrafficSignsControls old) {
    super.didUpdateWidget(old);
    if (!old.selected && widget.selected) _refresh();
  }

  void onViewportChanged(LatLngBounds bounds) {
    _bounds = bounds;
    if (widget.selected) _refresh();
  }

  Future<void> _refresh({bool force = false}) async {
    if (_bounds == null || (!widget.selected && !force)) return;
    final current = ++_generation;
    final store = ImportedRoadSigns.instance;
    if (store.count == 0) return;
    try {
      final markers = await store.markersInBounds(_bounds!);
      if (mounted && current == _generation) {
        widget.onMarkersChanged(markers);
      }
    } catch (_) {
      // Giữ bản đồ hiện tại nếu không đọc được SQLite.
    }
  }

  Future<void> _import() async {
    if (GpsTracker.useMock) {
      _notice('Nhập CSV chỉ có trên điện thoại thật');
      return;
    }
    try {
      final file = await openFile(acceptedTypeGroups: <XTypeGroup>[_csv]);
      if (file == null) return;
      final count = await ImportedRoadSigns.instance.importCsv(file);
      if (!mounted) return;
      widget.onSelected(true);
      await _refresh(force: true);
      if (mounted) {
        _notice('Đã lưu ' + count.toString() +
            ' biển từ ' + file.name + ' trên điện thoại');
      }
    } catch (_) {
      if (mounted) _notice('Không nhập được CSV. Kiểm tra dung lượng '
          'và chọn traffic_signs.csv hoặc speed_limit_signs.csv.');
    }
  }

  void _notice(String message) =>
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: ImportedRoadSigns.instance,
    builder: (context, _) {
      final store = ImportedRoadSigns.instance;
      return Material(
        color: Colors.transparent,
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          FilterChip(
            key: const Key('toggle_reference_speed_signs'),
            label: Text(store.count == 0
                ? 'Biển tham khảo' : 'Biển: ' + store.count.toString()),
            selected: widget.selected,
            onSelected: store.busy ? null : widget.onSelected,
          ),
          IconButton(
            key: const Key('import_road_signs_csv'),
            tooltip: 'Nhập CSV biển báo từ điện thoại',
            onPressed: store.busy ? null : _import,
            color: Colors.white,
            icon: store.busy
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file_outlined),
          ),
        ]),
      );
    },
  );
}
