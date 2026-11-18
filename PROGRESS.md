# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 18/11/2026 (giờ Việt Nam). Repository: `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

## Đã làm

- **Bước 1:** khởi tạo Flutter `bot_taximeter_pro`, Riverpod, GoRouter 7 route, `kCI`, 5 file CI/CD từ Phụ lục A.
- **Bước 2:** theme navy/cyan, kính mờ `BackdropFilter`, Be Vietnam Pro qua `google_fonts`, `AppShell`, `GlassCard`, `NeonButton`, `MapControlButtons`, `StatCard`, `RoutePreviewPainter`.
- **Bước 3:** Màn Home mock với bản đồ `CustomPainter`, chip trạng thái, số tốc độ và biển giới hạn minh họa, điều khiển 2D/3D/giao thông, nút điều hướng. Có `test/home_page_test.dart`.
- **Sửa lỗi CI #5:** widget test `Biển tốc độ mẫu cho phép chọn số minh họa` tìm `80` trước khi hộp chọn đóng. Đã sửa đúng `test/home_page_test.dart` để pump nhiều frame; commit `5fb52f2`, **chưa có CI xác nhận**.
- **Bước 4:** Màn 2 `SearchPage`: ô tìm kiếm, nút xóa/micro mô phỏng, sáu chip danh mục, bản đồ nhỏ vẽ nội bộ, chọn địa điểm, `Chọn điểm đi` và `Chọn điểm đến`, danh sách `Kết quả tìm kiếm`, `Tìm kiếm gần đây` và xóa các mục. Dữ liệu POI/địa chỉ/khoảng cách là minh họa.
- **Bước 4:** Màn 3 `RoutePage`: chọn điểm đi/dừng/đến, thêm và bỏ điểm dừng, đảo chiều, ba phương án `Nhanh nhất`/`Ít phí`/`Ít kẹt xe`, bản đồ polyline mẫu với tuyến được chọn và 2 tuyến thay thế, 4 số liệu ETA/quãng đường/cước/BOT, tổng quan lộ trình, nút `Bắt đầu dẫn đường` và `Lưu tuyến` (thông báo chưa có lưu thật).
- Liên thông lựa chọn địa điểm từ Màn 2 đến Màn 3 bằng `GoRouterState.extra` (map String/String). Điều hướng `Bắt đầu dẫn đường` mở Màn 4 hiện tại.
- Thêm `test/search_route_page_test.dart` kiểm tra chọn điểm đến, cập nhật tuyến, đổi phương án và chuyển Màn 4.
- Không sửa 5 file bộ CI, `ci/debug.keystore`, `integration_test/app_smoke_test.dart`, dữ liệu `docs/design/` hoặc các màn 4–7.

## Cây thư mục hiện tại

```text
.
├── .github/workflows/ci.yml
├── .gitignore
├── PROGRESS.md
├── README.md
├── analysis_options.yaml
├── ci/
│   ├── debug.keystore              (CI tự tạo, không sửa)
│   └── scripts/{prepare_android.sh,patch_android.py,make_report.py}
├── docs/design/                    (7 ảnh thiết kế và README.md)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/
│   │   ├── app_config.dart
│   │   ├── router/app_router.dart
│   │   └── theme/app_colors.dart
│   ├── features/map_tracking/presentation/
│   │   ├── home_page.dart
│   │   ├── home_map_mock.dart
│   │   ├── home_widgets.dart
│   │   ├── mock_travel_data.dart
│   │   ├── search_page.dart
│   │   └── route_page.dart
│   ├── shared/
│   │   ├── app_shell.dart
│   │   ├── glass_widgets.dart
│   │   └── route_preview_painter.dart
│   └── main.dart
├── pubspec.yaml
└── test/
    ├── home_page_test.dart
    └── search_route_page_test.dart
```

`android/` được CI tạo lại khi chạy, không commit vào repo.

## Dependencies và phiên bản

| Package | Phiên bản |
|---|---|
| `flutter_riverpod` | `3.5.0` |
| `go_router` | `18.1.4` |
| `google_fonts` | `8.1.0` |
| `flutter_lints` (dev) | `6.0.0` |
| `flutter_test` (dev) | Flutter SDK |
| `integration_test` (dev) | Flutter SDK |

Dart SDK `>=3.12.0 <4.0.0`. CI hiện sử dụng Flutter **3.50.0** stable theo báo cáo #5. Có thể ghim `FLUTTER_VERSION=3.50.0` trên GitHub.

## Quyết định kỹ thuật

- Bước 4 tiếp tục **mock trước, logic thật sau**. Lọc tìm kiếm bằng chuỗi và danh sách POI cục bộ; dữ liệu không lấy từ Nominatim, OSRM, Overpass hay API Google. Không tự động gọi mạng khi nhập ký tự.
- `mock_travel_data.dart` giữ dữ liệu POI mẫu và `MockRoutePainter` có ba polyline mẫu; màn Tìm kiếm tái sử dụng `HomeMockMapPainter` với chip 2D/3D/giao thông.
- Thông tin ETA, km, giá ước tính và phí BOT chỉ là số minh họa theo ảnh thiết kế, không dùng để báo giá hay điều hướng thật.
- Tab `Nhanh nhất`/`Ít phí`/`Ít kẹt xe` thay đổi tuyến canvas và thông số mẫu. Điều khiển 2D/3D và giao thông trên màn tuyến chỉ là giao diện thử, chưa có SDK bản đồ thật.
- Màn Tìm kiếm nhận từ khóa và lọc danh mục **offline**; phần micro chỉ hiển thị thông báo. Lưu lịch sử tìm kiếm tạm thời trong state; không lưu máy.
- Màn Lập tuyến cho phép sửa điểm đi, điểm dừng, điểm đến và đảo chiều. `Lưu tuyến` chỉ hiển thị thông báo, không giả vờ đã ghi vào SQLite.
- Điều hướng dùng `GoRouter` cũ; giữ nguyên các nhãn giao diện smoke test. Không thêm dependency ở Bước 4.
- `kCI` không gọi GPS, GoogleMap hoặc mạng. Chưa có animation vô hạn mới.
- Package Android hiện dùng `vn.bottaximeter.bot_taximeter_pro` theo lựa chọn người dùng.

## Kết quả CI gần nhất

- Báo cáo: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1
- **CI #5**, commit `3fde08e`: `flutter analyze` đạt, `flutter test` lỗi 1 bài test tốc độ, build APK debug đạt, smoke test Android 13 đạt.
- Nguyên nhân test: `expect(find.text('80'))` chạy sau thời gian bơm frame chưa đủ cho bottom sheet đóng và widget cập nhật. Đã bổ sung bơm frame trong `test/home_page_test.dart`, commit `5fb52f2`; chưa có báo cáo mới xác nhận.
- **Chưa có kết quả CI cho commit Bước 4**; không xác nhận các test mới đạt cho tới khi có báo cáo đúng commit.
- SHA-1 khóa debug: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.

## Lỗi đã biết / rủi ro

- Môi trường tác giả không có Flutter SDK; không thể chạy `flutter analyze`/`flutter test` trực tiếp. Dựa vào báo cáo CI và chỉ sửa đúng file gây lỗi ở lượt tiếp.
- Mọi giá trị tìm kiếm, tuyến, ETA và cước hiển thị chỉ là mẫu; không dùng cho điều hướng thực tế hoặc báo cước.
- Dịch vụ `speech_to_text`, Nominatim, OSRM và lưu lịch sử thật chưa được tích hợp (đúng lộ trình).
- App đang sử dụng keystore debug cố định trên repo **public**, có nguy cơ bị dùng để ký APK giả. Nên đặt repo private.
- Font Be Vietnam Pro tải lần đầu có thể cần Internet; cần thử fallback offline trên thiết bị.

## Cần thử trên điện thoại

- Redmi Note 12 Pro: mở hai màn mới, cuộn xem đủ nội dung, xem có tràn chữ hoặc nút quá nhỏ.
- Kiểm tra tìm kiếm từ khóa, chip lọc, chọn mục từ danh sách, chọn điểm đi/đến rồi chuyển sang tuyến, đổi 3 phương án, thêm/xóa điểm dừng, đảo chiều, bắt đầu dẫn đường.
- Kiểm tra tiếng Việt trong TextField khi mở bàn phím và hành vi nút quay lại.
- Các bước sau: GPS thật, quyền Android 13/14, độ chính xác, camera Maps, âm báo/foreground service, tối ưu pin MIUI.

## Việc tiếp theo

**Bước tiếp theo: 5** — Màn 4 Đang chạy chuyến (mock, đồng hồ chạy giả), dùng bộ shared widgets và giữ nguyên nhãn smoke test.
