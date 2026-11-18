# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 18/11/2026 (giờ Việt Nam). Repository: `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

## Đã làm

- **Bước 1:** Khởi tạo Flutter, Riverpod, GoRouter (7 tuyến), cờ `kCI`, bộ GitHub Actions từ Phụ lục A.
- **Bước 2:** Theme navy/cyan, `AppShell`, `GlassCard`, `NeonButton`, `MapControlButtons`, `StatCard`, `RoutePreviewPainter`; `google_fonts` (CI dùng font hệ thống).
- **Bước 3:** Home mock, bản đồ `CustomPainter`, nút điều hướng, tốc độ/giới hạn mẫu, chuyển 2D/3D, Follow xe, nút bắt đầu/lịch sử.
- **Bước 4:** SearchPage, RoutePage, 6 nhóm POI và 3 tuyến giả lập, truyền điểm đi/đến qua GoRouter, có test giao diện.
- **Bước 5:** `TripPage` cho Màn 4: chip GPS/3D/Follow xe, thẻ dẫn đường `Tiếp tục đi thẳng · 800 m`, map/tuyến giả, tốc độ/biển 60, nhóm nút 2D/3D/định vị/giao thông, pill tên đường, 4 thẻ số liệu, cảnh báo kẹt xe, các nút Tạm dừng/Tiếp tục/Kết thúc/SOS, cộng phí BOT thủ công.
- Đồng hồ mẫu dùng `Timer.periodic` tăng 1 giây/lần. Khi đang chạy tăng thời gian chuyến; khi tạm dừng tăng thời gian chờ. Cước mô phỏng khởi điểm 72.000 đ và tăng 1.000 đ/20 giây đang chạy; có thể cộng phụ phí BOT. **Đây không phải bảng giá hay đồng hồ taxi kiểm định**.
- Nút Kết thúc hiện xác nhận rồi chuyển sang màn biên lai placeholder; gửi snapshot mẫu (tổng tiền/quãng đường/thời gian/phụ phí) bằng `GoRouter.extra`. Màn Biên lai chính thức thực hiện ở Bước 7.
- SOS chỉ hiện hộp thoại rõ ràng rằng chưa gọi điện hay gửi vị trí. Hàng nút điều khiển được ghim cuối vùng nội dung để smoke test có thể bấm mà không cuộn.
- Thêm `test/trip_page_test.dart` kiểm tra đồng hồ giả/tạm dừng/tiếp tục/xác nhận kết thúc/SOS.
- **Sửa lỗi CI #8:** `flutter analyze` báo tham số `primary` không dùng trong `_NavButton` của `app_router.dart`; đã bỏ. `flutter test` và smoke test báo tràn 72 px ở `StatCard` trong RoutePage; tăng chiều cao ô bằng `childAspectRatio: 1.0`. Widget test Home bấm chip `80 km/h` ở tọa độ ngoài màn hình; chuyển test sang gọi callback của `ActionChip` và kiểm tra `HomeSpeedPanel.limitKmh` trực tiếp (thử cảm ứng thực trên điện thoại ở mục bên dưới).
- Giữ nguyên bộ CI, `ci/debug.keystore`, `integration_test/app_smoke_test.dart`, 7 ảnh thiết kế và các module không liên quan.

## Cây thư mục hiện tại

```text
.
├── .github/workflows/ci.yml
├── .gitignore
├── PROGRESS.md
├── README.md
├── analysis_options.yaml
├── ci/
│   ├── debug.keystore
│   └── scripts/{prepare_android.sh,patch_android.py,make_report.py}
├── docs/design/ (7 ảnh + README.md)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/
│   │   ├── app_config.dart
│   │   ├── router/app_router.dart
│   │   └── theme/app_colors.dart
│   ├── features/
│   │   ├── map_tracking/presentation/
│   │   │   ├── home_map_mock.dart
│   │   │   ├── home_page.dart
│   │   │   ├── home_widgets.dart
│   │   │   ├── mock_travel_data.dart
│   │   │   ├── route_page.dart
│   │   │   └── search_page.dart
│   │   └── trip/presentation/trip_page.dart
│   ├── shared/
│   │   ├── app_shell.dart
│   │   ├── glass_widgets.dart
│   │   └── route_preview_painter.dart
│   └── main.dart
├── pubspec.yaml
└── test/
    ├── home_page_test.dart
    ├── search_route_page_test.dart
    └── trip_page_test.dart
```

`android/` do CI tạo, chưa commit lên repo.

## Dependencies và phiên bản

| Package | Phiên bản |
|---|---|
| `flutter_riverpod` | `3.5.0` |
| `go_router` | `18.1.4` |
| `google_fonts` | `8.1.0` |
| `flutter_lints` (dev) | `6.0.0` |
| `flutter_test` (dev) | Flutter SDK |
| `integration_test` (dev) | Flutter SDK |

Dart SDK: `>=3.12.0 <4.0.0`. Flutter trong CI #8: **3.50.0** stable. Có thể ghim biến `FLUTTER_VERSION=3.50.0`.

## Quyết định kỹ thuật

- Bước 5 chỉ làm **UI và logic mô phỏng**. Không đo Haversine, GPS, thời gian đứng chờ thực tế, giá biểu phí thật, không gọi Maps, OSRM, Nominatim hay API trả phí.
- Để tránh thay đổi CI smoke test, giữ nguyên nhãn chính xác: `Tổng cước`, `Thời gian chờ`, `Tạm dừng`, `Tiếp tục`, `Kết thúc`, `Xác nhận`, `Biên lai chuyến đi`.
- Màn 4 dùng `AppShell(scrollable: false)`, phần số liệu/bản đồ có thể cuộn; hàng nút nằm cố định cuối thân trang.
- `TripPage` tái sử dụng `MockRouteMap`, `HomeSpeedPanel`, `HomeStatusChip`, `GlassCard`, `NeonButton`, `MapControlButtons`, `StatCard`.
- Timer hủy ở `dispose` và trước khi đổi sang biên lai. Pause không tăng thời gian di chuyển; thời gian chờ tăng trong chế độ pause chỉ để minh họa.
- Cược mẫu trong `TripPage` không được dùng để báo giá cho hành khách. Nút SOS chỉ cảnh báo về tình trạng chưa triển khai, không mô phỏng việc đã gọi thành công.
- Snapshot qua `GoRouter.extra` không lưu bền vững; sang Bước 7 sẽ liên kết với dữ liệu chuyến thật.
- Không thêm dependency mới, không sửa package Android `vn.bottaximeter.bot_taximeter_pro`.

## Kết quả CI gần nhất

- Báo cáo: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1
- **CI #8**, commit `42789db`: APK debug build đạt, `flutter analyze` lỗi 1 warning `unused_element_parameter`, `flutter test` lỗi 3 bài (2 tràn layout từ `glass_widgets.dart:220`, 1 do bấm `80 km/h` ngoài viewport), smoke test Android 13 lỗi Màn Tuyến đường vì tràn `StatCard`.
- Kiểm tra log job GitHub Actions thấy cảnh báo bấm text `80 km/h` tại offset Y=1272 ngoài viewport cao 940; nguyên nhân không phải thiếu thời gian bơm frame.
- Bản sửa trong commit Bước 5 nhắm tới đúng 3 nhóm lỗi trên. **Chưa có báo cáo CI xác nhận commit Bước 5**, không khẳng định toàn bộ test xanh.
- SHA-1 khóa debug: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.

## Lỗi đã biết / rủi ro

- Không có Flutter SDK chạy trực tiếp trong phiên này; cần GitHub Actions xác nhận phân tích, test và APK sau commit.
- Map, biển tốc độ, GPS, định tuyến, cảnh báo, tiền cước và thời gian khởi điểm đều là **mẫu**. Không sử dụng để xác định tốc độ an toàn hay tính tiền thật.
- Bản test tốc độ gọi callback để tránh vùng không thể hit-test, vì vậy thao tác thực tế trên máy vẫn cần kiểm tra.
- Repo hiện công khai và chứa `ci/debug.keystore` cố định; người khác có thể ký APK với chứng chỉ debug giống nhau. Nên chuyển repo private.
- SOS chưa có gọi điện/định vị; Google Maps và dịch vụ vị trí thật chưa tích hợp; Be Vietnam Pro offline cần kiểm tra.

## Cần thử trên điện thoại

- Redmi Note 12 Pro: mở Màn 4, cuộn xem bản đồ và thẻ thống kê 2×2 không tràn, điều khiển 2D/3D và nhãn tên đường.
- Chạm Tạm dừng, đợi vài giây để xem thời gian chờ tăng; Tiếp tục; mở Phụ phí BOT và cộng số tiền mẫu; xác nhận Kết thúc rồi xem biên lai.
- Chạm SOS để xác nhận chỉ có hộp thoại, không gọi thật.
- Ở Home: chọn biển tốc độ 60 rồi 80 bằng cảm ứng trên máy thực để xác minh bottom sheet và khu vực có thể chạm.
- Ở Màn Lập tuyến: xem bốn `StatCard` không bị overflow, xem nội dung trên màn hình nhỏ/keyboard mở.
- Bước sau cần thử GPS, Android foreground service và tối ưu pin MIUI khi có module thật.

## Việc tiếp theo

**Bước tiếp theo: 6 — Màn 5 Lịch sử & Doanh thu (`fl_chart`, dữ liệu mock).** Giữ nguyên nhãn smoke test.
