# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 18/11/2026, múi giờ Việt Nam.
Repo: `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

## Đã làm

- **Bước 1:** dự án Flutter `bot_taximeter_pro`, `ProviderScope`, GoRouter 7 tuyến, cờ `kCI`, CI/CD trong 5 file Phụ lục A, ghi mã ở `main`.
- **Bước 2:** AppTheme tối, màu cyan/neon navy, Be Vietnam Pro qua `google_fonts` (CI chọn font hệ thống), AppShell, GlassCard, NeonButton, MapControlButtons, StatCard, RoutePreviewPainter.
- **Sửa lỗi CI cũ:** báo cáo CI #3 (commit `c0f8343`) còn warning `unused_import` trong `integration_test/app_smoke_test.dart`. Đã kiểm tra và xóa lại import này, commit `f91f39b`; chưa có báo cáo kiểm chứng bản sửa.
- **Bước 3:** Home mock với khung chung AppShell, chip GPS/Google Maps 3D/Follow xe, bản đồ giả `HomeMockMapPainter`, cụm bản đồ 3D/2D/định vị/ngày-đêm/giao thông, số tốc độ 42 km/h và biển tốc độ mẫu 60 (chạm chọn được), vị trí xe và tên đường, 2 thẻ thông tin, 4 nút điều hướng, Bắt đầu và Lịch sử.
- Home có tương tác mẫu: chuyển 2D/3D, chế độ sáng/tối, lớp giao thông giả, Follow xe, ghi đè số trên biển minh họa, menu chức năng. Chỉ dùng `setState`, không đọc GPS hay gọi API.
- Route `/` dùng `HomePage` mới; giữ nguyên sáu màn placeholder và 7 đường dẫn GoRouter để CI smoke test không bị đổi luồng.
- Thêm `test/home_page_test.dart` kiểm tra bố cục/nhãn, chuyển 2D/3D, biển tốc độ mẫu và nút Tìm kiếm.
- Giữ nguyên `.github/`, `ci/`, `ci/debug.keystore`, thiết kế ở `docs/design/`, và mã nguồn ổn định của các màn khác.

## Cây thư mục hiện tại

```text
.
├── .github/workflows/ci.yml
├── .gitignore
├── PROGRESS.md
├── README.md
├── analysis_options.yaml
├── ci/
│   ├── debug.keystore               (do CI tự tạo, không sửa)
│   └── scripts/
│       ├── prepare_android.sh
│       ├── patch_android.py
│       └── make_report.py
├── docs/design/                     (7 ảnh + README)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/
│   │   ├── app_config.dart
│   │   ├── router/app_router.dart
│   │   └── theme/app_colors.dart
│   ├── features/map_tracking/presentation/
│   │   ├── home_page.dart
│   │   ├── home_map_mock.dart
│   │   └── home_widgets.dart
│   ├── shared/
│   │   ├── app_shell.dart
│   │   ├── glass_widgets.dart
│   │   └── route_preview_painter.dart
│   └── main.dart
├── pubspec.yaml
└── test/home_page_test.dart
```

`android/` chưa được commit, workflow tự sinh trong CI.

## Dependencies và phiên bản

| Package | Phiên bản |
|---|---|
| `flutter_riverpod` | `3.5.0` |
| `go_router` | `18.1.4` |
| `google_fonts` | `8.1.0` |
| `flutter_lints` (dev) | `6.0.0` |
| `flutter_test` (dev) | Flutter SDK |
| `integration_test` (dev) | Flutter SDK |

- Dart SDK: `>=3.12.0 <4.0.0`.
- CI #3 dùng **Flutter 3.50.0** stable. Nên đặt biến repo `FLUTTER_VERSION=3.50.0` để ghim phiên bản.

## Quyết định kỹ thuật

- Bước 3 chỉ là **dữ liệu minh họa**. Cả “GPS tốt”, “Google Maps 3D”, “42 km/h”, “60 km/h”, bản đồ, vị trí và tên đường đều không phản ánh thực tế. Người dùng được thông báo qua nhãn “BẢN ĐỒ MẪU” và khi chạm chip/biển.
- **Không dùng** `GoogleMap`, không gọi Google Maps SDK/API, không xin quyền GPS, không gọi Nominatim/OSRM; chi phí Maps của bước này bằng 0.
- `HomeMockMapPainter` vẽ các con đường và tòa nhà giả bằng `Canvas`. Chế độ 3D là hiệu ứng giả lập, không phải dữ liệu bản đồ 3D thật.
- Home dùng `AppShell`, các thẻ `GlassCard`/nút `NeonButton` và các component riêng; cỡ bản đồ dựa trên chiều cao màn hình, body có thể cuộn khi không đủ chỗ.
- Biển mẫu cho chọn 40–120 km/h chỉ thay đổi hiển thị tạm thời. Không có `SpeedLimitEngine`/cảnh báo vượt tốc (thực hiện Bước 12).
- Giá ước tính là con số mẫu. Giá cước thật chỉ có sau khi có điểm đến và FareCalculator ở các bước sau.
- Cờ `kCI` đã có, không chạy animation vô hạn. Các widget test dùng `MaterialApp.router` với theme hệ thống, không tải font hay gọi mạng.
- Package Android theo quyết định người dùng: `vn.bottaximeter.bot_taximeter_pro`. Cần cùng SHA-1 của khóa ký khi giới hạn Maps.

## Kết quả CI gần nhất

- Issue theo dõi: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1
- **CI #3, commit `c0f8343`:** Flutter 3.50.0; `flutter test` đạt; APK debug đạt; test giao diện Android 13 đạt; `flutter analyze` còn **1 warning** `unused_import`.
- Đã sửa file báo warning ở commit `f91f39b`. Chưa có báo cáo từ CI đúng commit Bước 3; **không xác nhận CI xanh cho lần push mới**.
- SHA-1 khóa debug đã được báo: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.

## Lỗi đã biết / rủi ro

- Không có Flutter SDK trong môi trường làm việc trực tiếp, nên chưa chạy `flutter analyze` / `flutter test` tại chỗ; cần kiểm chứng trong GitHub Actions sau commit Bước 3.
- Bản đồ, tốc độ, giao thông và quãng đường trên Home đều là **mô phỏng**, không dùng để điều khiển xe hay làm căn cứ pháp lý.
- Repo hiện công khai và có `ci/debug.keystore` ký debug cố định, nên có rủi ro người ngoài dùng cùng khóa để ký APK. Khuyến nghị repo private.
- Be Vietnam Pro có thể cần tải lần đầu trên máy thật; fallback offline cần kiểm tra và đóng gói font khi hoàn thiện.
- Màn 2–7 vẫn dùng UI placeholder. Chưa tích hợp dữ liệu GPS, tính cước thật, SQLite, định tuyến và thanh toán.

## Cần thử trên điện thoại

- Trên Redmi Note 12 Pro: kiểm tra bố cục Home, chữ không tràn, độ dễ bấm 5 nút bản đồ, hiển thị bảng số tốc độ và thanh chức năng.
- Thử nút 2D/3D, sáng/tối, giao thông giả, Follow xe, biển tốc độ mẫu, Bắt đầu và Lịch sử, điều hướng 4 chức năng.
- Về sau: GPS thực, tốc độ, độ chính xác, quyền Android 13/14, foreground service, tối ưu pin MIUI, bản đồ Google thật/traffic.
- Đối chiếu package `vn.bottaximeter.bot_taximeter_pro` và SHA-1 CI với thông số hạn chế khóa Google Maps.

## Việc tiếp theo

**Bước 4:** Màn 2 **Tìm kiếm** và Màn 3 **Lập tuyến đường**, cả hai dùng mock data. Giữ nguyên luồng, nhãn smoke test, không gọi API.
