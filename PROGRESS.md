# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 18/11/2026 (giờ Việt Nam). Repository `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

## Đã làm

- **Bước 1:** Tạo Flutter, Riverpod, GoRouter với 7 route và bộ CI/CD tại GitHub Actions.
- **Bước 2:** Theme navy/cyan neon, `AppShell`, `GlassCard`, `NeonButton`, `MapControlButtons`, `StatCard`, `RoutePreviewPainter`.
- **Bước 3:** Home mock, các chip GPS/3D/Follow, bản đồ CustomPainter, tốc độ/biển giới hạn, điều hướng.
- **Bước 4:** SearchPage và RoutePage mock, POI mẫu, ba tuyến mẫu, lựa chọn điểm đi/đến, ETA/cước minh họa.
- **Bước 5:** TripPage mock có đồng hồ Timer cập nhật từng giây, tạm dừng, chờ, cộng BOT, hộp thoại kết thúc/SOS; chuyển snapshot mẫu sang Biên lai.
- **Bước 6:** HistoryPage mock, bộ lọc Hôm nay/7 ngày/30 ngày, biểu đồ `fl_chart`, danh sách cuốc xe và chi tiết mẫu.
- **Sửa lỗi CI #10:** `flutter test` của Bước 6 báo `RenderFlex overflow` 18 px/2,4 px tại `StatCard` trên màn Lịch sử (lỗi từ `childAspectRatio: 1.25`). Đã đổi tỉ lệ thành `1.0` trong `lib/features/history/presentation/history_page.dart`. Chưa có CI kiểm chứng bản sửa này.
- **Bước 7, Màn 6:** `ReceiptPage` và `ReceiptRouteCard` với lộ trình `RoutePreview` (Canvas offline), mã cuốc, trạng thái, các dòng khách hàng/điểm đón/trả/thời gian/km/tiền chờ/phụ phí, `Tổng cước` nổi bật. Nhận snapshot qua `GoRouter.extra` từ Lịch sử hoặc màn Đang chạy chuyến.
- **Bước 7, VietQR giả:** chọn `Tiền Mặt` / `Chuyển Khoản` trên giao diện. Khi Chuyển Khoản hiện `QrImageView` mã hóa chuỗi **`BOT-TAXIMETER-PRO|DEMO|NOT-A-PAYMENT`**, có cảnh báo `KHÔNG THANH TOÁN`. Không chứa số tài khoản thật, không phải payload VietQR/EMVCo. Logo mẫu tại `assets/images/logo.png`. Ba nút `In biên lai`, `Chia sẻ`, `Xuất PDF` chỉ thông báo chưa triển khai (lộ trình Bước 13).
- **Bước 7, Màn 7:** `SettingsPage` với 2D/3D, Follow xe, góc camera 15°–80°, sáng/tối, giao thông, hiển thị tên đường; công tắc âm báo/cảnh báo/rung/tự 3D; loại xe và khu vực; ngân hàng/tên chủ TK/số TK; chuyển khoản mặc định; câu chào LED, kích cỡ chữ, chế độ đơn giản; khung xem trước `CustomPainter`.
- **Lưu cài đặt:** Nhấn `Lưu cài đặt` ghi các lựa chọn qua `shared_preferences`, tải lại khi mở màn. `Khôi phục mặc định` khôi phục trường trên màn hình, sau đó phải nhấn Lưu để ghi. ReceiptPage đọc tên ngân hàng, chủ tài khoản, số tài khoản và lựa chọn mặc định từ cấu hình đã lưu (QR vẫn là DEMO).
- **Bước 7 test:** `test/step7_pages_test.dart` kiểm tra biên lai nhận tổng tiền mẫu, QR mẫu hiện/ẩn khi đổi phương thức thanh toán, màn Settings hiển thị và lưu lựa chọn 2D. Giữ nguyên nhãn smoke test.
- Thêm `qr_flutter: 4.1.0`, `shared_preferences: 2.5.6` vào `pubspec.yaml`, giữ lại dependencies đã ghim.
- Bộ workflow CI, khóa debug, ảnh thiết kế và integration smoke test **không chỉnh sửa**.

## Cây thư mục hiện tại

```text
.
├── .github/workflows/ci.yml
├── .gitignore
├── PROGRESS.md
├── README.md
├── analysis_options.yaml
├── assets/images/logo.png (logo TTX placeholder)
├── ci/
│   ├── debug.keystore
│   └── scripts/{prepare_android.sh,patch_android.py,make_report.py}
├── docs/design/ (7 ảnh + README.md)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/{app_config.dart,router/app_router.dart,theme/app_colors.dart}
│   ├── features/
│   │   ├── history/presentation/
│   │   │   ├── history_mock_data.dart
│   │   │   ├── history_page.dart
│   │   │   └── history_widgets.dart
│   │   ├── map_tracking/presentation/
│   │   │   ├── home_map_mock.dart
│   │   │   ├── home_page.dart
│   │   │   ├── home_widgets.dart
│   │   │   ├── mock_travel_data.dart
│   │   │   ├── route_page.dart
│   │   │   └── search_page.dart
│   │   ├── receipt/presentation/
│   │   │   ├── receipt_page.dart
│   │   │   └── receipt_widgets.dart
│   │   ├── settings/presentation/
│   │   │   ├── settings_page.dart
│   │   │   └── settings_widgets.dart
│   │   └── trip/presentation/trip_page.dart
│   ├── shared/{app_shell.dart,glass_widgets.dart,route_preview_painter.dart}
│   └── main.dart
├── pubspec.yaml
└── test/
    ├── history_page_test.dart
    ├── home_page_test.dart
    ├── search_route_page_test.dart
    ├── step7_pages_test.dart
    └── trip_page_test.dart
```

`android/` do CI tạo khi build, không commit lên repo.

## Dependencies và phiên bản

| Package | Phiên bản |
|---|---|
| `flutter_riverpod` | `3.5.0` |
| `go_router` | `18.1.4` |
| `google_fonts` | `8.1.0` |
| `fl_chart` | `1.3.1` |
| `qr_flutter` | `4.1.0` (thêm Bước 7) |
| `shared_preferences` | `2.5.6` (thêm Bước 7) |
| `flutter_lints` (dev) | `6.0.0` |
| `flutter_test` (dev) | Flutter SDK |
| `integration_test` (dev) | Flutter SDK |

Dart SDK: `>=3.12.0 <4.0.0`. CI #10 dùng Flutter `3.50.0` stable; có thể ghim `FLUTTER_VERSION=3.50.0`.

## Quyết định kỹ thuật

- **Bước 7 là UI mock** theo đúng mục 10 Master Prompt. VietQR chuẩn EMVCo/CRC16, cache BIN ngân hàng, PDF/in/chia sẻ thực, ghi lịch sử SQLite sẽ làm ở **Bước 13**. Không tự sinh số tài khoản/ngân hàng giả để tạo QR thanh toán có thể dùng thật.
- QR demo dùng `qr_flutter` chế độ sửa lỗi H và logo giữa mã, nhưng payload là chuỗi văn bản DEMO không thể thực hiện lệnh chuyển tiền. Có nhãn nổi bật `KHÔNG THANH TOÁN`.
- Hình bản đồ trong biên lai và xem trước ở Settings chỉ vẽ `CustomPainter`/tuyến mẫu; không khởi tạo `GoogleMap` thứ hai, không gọi Static Maps API.
- Chỉ lưu cấu hình trên thiết bị bằng `SharedPreferences`; dữ liệu ngân hàng là trường tự nhập, **shared_preferences không phải kho lưu trữ mã hóa**, tuyệt đối không nhập mật khẩu, OTP. Khi triển khai thanh toán thật cần rà soát bảo mật, dữ liệu cá nhân và xác nhận người dùng trước khi bật QR.
- Cài đặt nút bản đồ/cảnh báo/âm báo hiện chỉ thay đổi và lưu UI; chưa kích hoạt xử lý GPS, camera hay cảnh báo thật. Phần liên kết áp dụng lên `SharedMapView` thuộc Bước 8 và GPS/Rules các bước sau.
- ReceiptPage vẫn giữ nhãn `Biên lai chuyến đi` để smoke test. Các thao tác chưa triển khai hiển thị thông báo rõ ràng, không giả báo thành công.
- Toàn bộ file Dart mới đều dưới 300 dòng; bước này sửa thêm 1 file Dart cũ do lỗi CI của Bước 6.
- Package Android vẫn là `vn.bottaximeter.bot_taximeter_pro`; SHA-1 không thay đổi.

## Kết quả CI gần nhất

- Báo cáo: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1
- **CI #10**, commit `f731fad` (Bước 6): `flutter analyze` ✅, `flutter test` ❌ (2 bài test Lịch sử bị `RenderFlex overflow`), APK debug ✅, smoke test Android 13 ✅.
- Log job xác nhận overflow tại `lib/shared/glass_widgets.dart:220`, constraint nội dung cao 121,6 px; đã sửa nguồn chiều cao grid trong `history_page.dart` từ 1,25 xuống 1,0.
- **Chưa có CI xác nhận commit Bước 7**. Chưa thể khẳng định build/test Bước 7 đạt; chờ GitHub Actions sau lần push.
- SHA-1 khóa debug: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.

## Lỗi đã biết / rủi ro

- Chưa kiểm thử Bước 7 trên Flutter SDK tại chỗ; cần CI kiểm tra dependency mới, layout và dữ liệu preferences.
- Các số tiền, địa chỉ, thời gian, biểu đồ, tuyến và QR trình diễn hoàn toàn không phải giao dịch thật.
- Nút in/chia sẻ/PDF chưa tạo tài liệu; chức năng này nằm trong Bước 13. SOS/GPS/Maps thật cũng chưa được tích hợp.
- Repository công khai đang lưu khóa `ci/debug.keystore`, có rủi ro bị dùng ký APK khác cùng chứng chỉ. Khuyến nghị chuyển repo private.
- Lưu cài đặt ngân hàng hiện không mã hóa trong shared_preferences. Chỉ lưu thông tin nhận tiền, không lưu dữ liệu xác thực.

## Cần thử trên điện thoại

- Redmi Note 12 Pro: mở Lịch sử → Xem chi tiết để xem biên lai, chọn Tiền Mặt/Chuyển Khoản, xác nhận QR có cảnh báo không thanh toán, xem đủ thông tin và không tràn bố cục.
- Từ Home → Cài đặt: thử 2D/3D, góc nghiêng 15–80°, sáng/tối, Follow xe, giao thông, tên đường, âm báo, cảnh báo, rung, loại xe/khu vực và chế độ đơn giản.
- Nhập thử dữ liệu cấu hình **không nhạy cảm**, nhấn Lưu cài đặt, đóng mở ứng dụng để xác nhận tùy chọn còn; Khôi phục mặc định rồi Lưu lại.
- Kiểm tra khi chưa có mạng, ảnh logo placeholder và font tiếng Việt vẫn xuất hiện, nút In/Chia sẻ/PDF có thông báo chưa khả dụng.
- Thử toàn bộ smoke flow cũ: Home → Bắt đầu → Tạm dừng → Tiếp tục → Kết thúc → Xác nhận → Biên lai, và Home → Cài đặt.
- Các bước sau cần kiểm tra Maps API, GPS, camera, speed rules, foreground service/MIUI.

## Việc tiếp theo

**Bước tiếp theo: 8 — SharedMapView Google Maps thật**, style tối/sáng, tilt, buildings, traffic, marker xe, Follow xe và chế độ CI không gọi mạng.
