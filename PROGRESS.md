# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 18/11/2026 (giờ Việt Nam). Repository `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

## Đã làm

- **Bước 1:** Khởi tạo Flutter/Riverpod/GoRouter 7 route; Android tạo trong CI; bộ CI chuẩn Phụ lục A.
- **Bước 2:** Theme navy/cyan, kính mờ, `AppShell`, nút neon, ô thống kê và bộ nút bản đồ.
- **Bước 3:** Home mock, chip, tốc độ/biển mẫu, tìm kiếm, tuyến, doanh thu, cài đặt.
- **Bước 4:** Tìm kiếm và lập tuyến mẫu, POI/offline 3 phương án và các màn chuyển tiếp.
- **Bước 5:** Đang chạy chuyến mock, `Timer`, tạm dừng, phụ phí, kết thúc, SOS minh họa.
- **Bước 6:** Lịch sử/doanh thu mock, `fl_chart`, ba bộ lọc và danh sách cuốc.
- **Bước 7:** Biên lai mẫu + QR chỉ chứa chuỗi DEMO, Cài đặt lưu bằng `shared_preferences`.
- **Bước 8:** `SharedMapView` với Google Maps SDK, 2D/3D, style dark/light, traffic layer, marker xe tự vẽ, 3 polyline mẫu và Canvas fallback trong CI.
- **Bước 9: GPS thật và xử lý dữ liệu.** Thêm `GpsTracker` singleton ChangeNotifier và `GpsFilter` Dart thuần với Haversine, ngưỡng accuracy ≤25m, bước nhảy ≤200km/h, chỉ cộng mét ≥5m và tốc độ làm mượt ≥3km/h. Đo tốc độ thật khi được cấp quyền; hiện accuracy tốt/yếu và cập nhật marker xe trong `SharedMapView`. Không hiển thị marker giả nếu không có fix GPS hợp lệ.
- Trên **Home**, chạm chip GPS để xem mô tả quyền và yêu cầu vị trí khi sử dụng. Khi có fix hợp lệ, cập nhật tọa độ, heading, tốc độ; tên đường có thể tra theo thao tác chạm. **RoutePage** hiển thị vị trí GPS hiện có; các polyline và ETA vẫn là dữ liệu mẫu.
- Trên **Màn Đang chạy chuyến**, sau khi tài xế vào màn sẽ hỏi quyền vị trí, sau đó quyền thông báo Android 13+; dùng `AndroidSettings.foregroundNotificationConfig` với thông báo `Đang chạy chuyến` để theo dõi trong khi app chuyển ra nền. `wakelock_plus` giữ sáng màn hình trong chuyến và tắt khi rời màn. Nút `Cài đặt pin Xiaomi / Redmi` hướng dẫn tự thay đổi tối ưu pin, không tự cấp quyền.
- Thêm `TripMapPanel` để tách phần bản đồ khỏi `TripPage` và giữ giới hạn 300 dòng/file. Màn Trip hiển thị quãng đường Haversine (khi có fix thật), tốc độ thực; khi tạm dừng không cộng quãng đường. Biển giới hạn 60, chỉ dẫn rẽ, tổng cước và phụ phí vẫn là **mẫu**.
- `GeocodingProvider` interface và `NominatimGeocodingProvider` hỗ trợ reverse geocode qua **máy chủ HTTPS riêng/được cấp phép**, chỉ khi người dùng chạm yêu cầu. Cache ô xấp xỉ 50m, tối thiểu 1,2 giây giữa request, mỗi lần một request, timeout và LRU đơn giản 256 ô. Không gửi request theo lưới hoặc mỗi giây; mặc định không có URL nên không truyền GPS ra mạng cho geocoder. Chính sách OSM yêu cầu không sử dụng dịch vụ Nominatim công cộng như một API định vị xe hàng loạt, vì vậy mã chặn host công cộng.
- Unit tests mới: `gps_filter_test.dart` (Haversine, accuracy, tốc độ, jump, pause và làm mượt); `road_name_provider_test.dart` (no-network mặc định, cache/rate limit bằng fake); `gps_tracker_test.dart` (CI không dùng plugin).
- **CI #13 cho Bước 8 `8634f59`: flutter analyze ✅, flutter test ✅, build APK debug ✅, smoke test Android 13 ✅.** Bước 9 chưa có CI cho commit mới, không kết luận xanh trước báo cáo.
- Không đổi file CI, keystore, smoke test hoặc dữ liệu ảnh. Package giữ `vn.bottaximeter.bot_taximeter_pro`.

## Cây thư mục

```text
.
├── .github/workflows/ci.yml
├── .gitignore, analysis_options.yaml, README.md, PROGRESS.md
├── assets/images/logo.png
├── assets/map_styles/{dark.json,light.json}
├── ci/debug.keystore
├── ci/scripts/{prepare_android.sh,patch_android.py,make_report.py}
├── docs/
│   ├── GPS_SETUP.md
│   ├── GOOGLE_MAPS_SETUP.md
│   └── design/ (7 ảnh thiết kế + README)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/{app_config.dart,router/app_router.dart,theme/app_colors.dart}
│   ├── features/
│   │   ├── history/presentation/
│   │   ├── map_tracking/
│   │   │   ├── data/{gps_filter.dart,gps_tracker.dart,road_name_provider.dart}
│   │   │   └── presentation/{gps_permission_prompt.dart,
│   │   │       home_map_mock.dart,home_page.dart,home_widgets.dart,
│   │   │       mock_travel_data.dart,route_page.dart,search_page.dart}
│   │   ├── receipt/presentation/
│   │   ├── settings/presentation/
│   │   └── trip/presentation/{trip_map_panel.dart,trip_page.dart}
│   ├── shared/{app_shell.dart,glass_widgets.dart,
│   │           route_preview_painter.dart,shared_map_view.dart}
│   └── main.dart
├── pubspec.yaml
└── test/ (các test Bước 1–8 + gps_filter_test.dart,
           road_name_provider_test.dart, gps_tracker_test.dart)
```

`android/` được `flutter create` tự tạo trong CI, không commit.

## Dependencies và phiên bản

| Package | Version |
|---|---|
| `flutter_riverpod` | 3.5.0 |
| `go_router` | 18.1.4 |
| `google_fonts` | 8.1.0 |
| `fl_chart` | 1.3.1 |
| `qr_flutter` | 4.1.0 |
| `shared_preferences` | 2.5.6 |
| `google_maps_flutter` | 2.19.0 |
| `geolocator` | **14.1.2** (Bước 9) |
| `permission_handler` | **12.0.3** (Bước 9, tương thích compileSdk ≥35 thay vì v13 đòi SDK37) |
| `wakelock_plus` | **1.8.0** (Bước 9; tránh xung đột `dbus` với geolocator Linux) |
| `flutter_lints` | 6.0.0 (dev) |

Dart SDK >=3.12.0 <4.0.0. Flutter trong CI #13: 3.50.0 stable. Nên đặt repo variable `FLUTTER_VERSION=3.50.0`.

## Quyết định và giới hạn kỹ thuật

- Bước 9 dùng nguồn vị trí **trực tiếp từ thiết bị khi tài xế cho phép**; không lấy vị trí từ cuộc trò chuyện hay một địa chỉ gán mặc định.
- `GpsTracker.useMock` bật khi `CI=true` hoặc `FLUTTER_TEST=true`, không gọi `Geolocator`, `permission_handler`, `WakelockPlus` hoặc geocoding; UI mock vẫn hiện chữ `GPS tốt` để giữ smoke test cũ.
- `GpsFilter` thuần Dart kiểm soát nhiễu, không bảo đảm độ chính xác 100%. Trước khi tính cước thật phải có FareEngine, kiểm chứng thực địa, trạng thái chuyến và snapshot định kỳ (Bước 10).
- `GpsTracker.start(trip:true)` chỉ được gọi sau khi tài xế đồng ý; khởi chạy stream Android Foreground NotificationConfig. `stop` hủy stream/wakelock, xóa fix và tên đường để không dùng vị trí cũ.
- AndroidManifest đã có quyền `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `WAKE_LOCK` từ `patch_android.py`. Không tự yêu cầu `ACCESS_BACKGROUND_LOCATION`; Android yêu cầu service foreground được bắt đầu khi app đang hiển thị và quyền location khi dùng.
- Không tự yêu cầu `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: cung cấp hướng dẫn và mở app settings sau khi người dùng bấm. Không có bảo đảm Android/MIUI không hủy app trong nền.
- **Nominatim policy:** dịch vụ công cộng có giới hạn 1 req/giây cho toàn bộ ứng dụng, cấm reverse theo lưới và cảnh báo đối với app theo dõi xe. Vì vậy chỉ hỗ trợ máy chủ đã được phê duyệt qua `--dart-define=GEOCODING_BASE_URL=...`, mặc định tắt; không gọi public host. Không tự tải mỗi khi GPS thay đổi; chỉ tra theo chạm tên đường. Xem `docs/GPS_SETUP.md`. Tên đường nguồn OpenStreetMap cần ghi công.
- Cước và biển tốc độ vẫn là mẫu, không sử dụng để thu tiền hoặc chỉ dẫn lái xe. Chưa có OSRM, FareCalculator, speed rule engine.
- GPS foreground service chỉ sống khi Dart app duy trì stream; chưa có persist/snapshot chuyến, tiến trình có thể bị Android giết. Bước 10 và 14 sẽ cải thiện độ bền/MIUI.

## CI và APK

- Báo cáo: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1
- **CI #13** (commit `8634f59`), 4/4 hạng mục đều đạt: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions/runs/44274743679
- **CI #14**, commit `ba9383e`: thất bại ở `flutter create / pub get` vì `wakelock_plus 1.8.2` yêu cầu `dbus ^0.8.0` trong khi `geolocator_linux` yêu cầu `dbus ^0.7.3`. Chưa chạy analyzer/test/APK. Đã ghim lại `wakelock_plus 1.8.0` theo gợi ý resolver; chờ CI commit sửa lỗi xác nhận.
- SHA-1 debug CI: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.
- Repo public có debug keystore cố định; nên chuyển private. Google Maps key nằm trong GitHub Secret `MAPS_API_KEY`, không commit vào repo.

## Cần thử trên điện thoại

- Redmi Note 12 Pro: bật Vị trí, trên Home chạm chip GPS, chọn quyền `Trong khi sử dụng`; kiểm tra trạng thái, marker xe thật, tốc độ từ GPS, tự về vị trí khi Follow xe.
- Di chuyển thử nơi an toàn để so vị trí/tốc độ, đi chậm dưới 3km/h, tín hiệu yếu, tắt GPS giữa chuyến, trạng thái khi quyền từ chối. Không thao tác điện thoại khi đang lái.
- Vào Màn Chuyến, đồng ý quyền thông báo, kiểm tra thông báo `Đang chạy chuyến`, thử tắt màn hình/đổi app, sau đó quay lại xem số mét; chạm `Cài đặt pin Xiaomi / Redmi` nếu cần.
- Tạm dừng, kiểm tra quãng đường không tăng; kết thúc, xác nhận thông báo foreground/wakelock dừng.
- Tên đường: mặc định không truy vấn; muốn thử cần endpoint Nominatim riêng hợp lệ và build với Dart define.
- Test hồi quy tất cả 7 màn, đặc biệt UI CI và smoke test Android 13.

## Việc tiếp theo

**Bước tiếp theo: 10 — Fare engine, state machine chuyến đi, unit test, snapshot 3 giây và khôi phục chuyến sau khi app bị đóng.**
