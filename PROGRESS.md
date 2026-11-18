# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 18/11/2026 (giờ Việt Nam). Repo `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

## Đã làm

- **Bước 1–2:** Flutter + Riverpod + GoRouter, bộ CI chuẩn từ Phụ lục A, giao diện navy/cyan và widget dùng chung.
- **Bước 3–4:** Home, Tìm kiếm và Lập tuyến bằng dữ liệu mẫu, các màn cùng điều hướng qua GoRouter.
- **Bước 5–6:** Màn chạy chuyến mẫu, lịch sử/doanh thu mẫu, `fl_chart` và bộ lọc.
- **Bước 7:** Màn biên lai mẫu, QR chỉ chứa chuỗi DEMO, Cài đặt lưu bằng `shared_preferences`.
- **Bước 8:** `SharedMapView` dùng Google Maps Android, 2D/3D, traffic, Follow; CI dùng Canvas.
- **Bước 9:** `GpsTracker`, Haversine, lọc nhiễu, foreground notification/wakelock khi đã được cấp quyền, tên đường qua geocoder tùy chọn. **CI #16 commit `960bdf5`: flutter analyze ✅, flutter test ✅, build APK arm64 ✅, smoke test Android 13 ✅.**
- **Bước 10:** Thêm `FareConfig`/`FareCalculator` thuần Dart, các bậc theo Master Prompt: mở cửa 30.000 đ gồm 1,5 km; 1,5–30 km = 13.000 đ/km; 30–50 km = 11.500 đ/km; trên 50 km = 10.000 đ/km; chờ 30.000 đ/giờ sau 5 phút miễn phí (tùy chỉnh trong Cài đặt). BOT cộng sau bước làm tròn.
- `roundVnd`: phần dư **> 500** mới làm tròn lên; phần dư đúng **500** làm tròn xuống. Có unit test cho 0,1,499,500,501,999 và các mốc km/phí chờ/BOT.
- **TripController** là nơi duy nhất chuyển trạng thái: enum `idle → pickingUp → inTrip ⇄ waiting → completed`; trạng thái `pickingUp` dành cho tương lai. `Tạm dừng`/ `Tiếp tục` đi qua controller. Tùy chọn tự chuyển vào `waiting` sau 10 giây ở tốc độ GPS dưới 3 km/h mặc định **tắt**; không kích hoạt tự động khi chưa có GPS. Tạm dừng thủ công không bị tự động bật lại theo tốc độ.
- Thời gian chờ tích lũy theo số giây khi ở `waiting`, quãng đường từ chênh lệch Haversine đã lọc của `GpsTracker`. Không tính thêm khoảng thời gian app đã đóng hoặc không có tick, không nối khoảng cách giữa điểm cuối trước khôi phục và vị trí GPS đầu tiên sau khôi phục.
- **SQLite:** `sqflite` tạo bảng `trip_snapshots` trong `bot_taximeter.db`; lưu một snapshot đang chạy qua JSON mỗi **3 giây** và tại các thay đổi trạng thái/BOT. Các thao tác ghi chạy tuần tự; khi kết thúc thì đợi ghi xong rồi xóa snapshot. CI/unit test dùng `MemoryTripStore`, không gọi SQLite native.
- **Khôi phục:** `main.dart` kiểm tra snapshot khi ứng dụng khởi động, mở màn Trip để hỏi **“Khôi phục chuyến đang chạy?”**. Tài xế chọn Khôi phục hoặc Bỏ chuyến cũ. Đồng hồ không tự cộng thêm quãng thời gian khi app đã đóng.
- **Màn Đang chạy chuyến** hiển thị tổng cước/quãng đường/giây chờ từ controller, có cộng BOT chọn nhanh/nhập thủ công, xác nhận Kết thúc và truyền số liệu về màn Biên lai. Cước hiển thị là **tham khảo theo GPS, chưa phải đồng hồ taxi kiểm định**. Không có GPS hợp lệ thì không có quãng đường tính mới.
- **Cài đặt → Biểu phí & Phí chờ:** chỉnh 5 đơn giá, tổng số phút miễn phí (0/3/5/10/15 hoặc số tùy chỉnh 0–1440), bật/tắt tự Waiting. Lưu trên thiết bị bằng `shared_preferences`, đọc khi bắt đầu một cuốc mới. Cấu hình của cuốc đang chạy nằm trong snapshot, không thay đổi giữa chuyến.
- Các bài kiểm thử mới: `test/fare_calculator_test.dart`, `test/trip_controller_test.dart`; cập nhật `test/trip_page_test.dart` bỏ số liệu giả 72.000 đ/14:26. Giữ nguyên nhãn CI `Tổng cước`, `Thời gian chờ`, `Tạm dừng`, `Tiếp tục`, `Kết thúc`, `Biên lai chuyến đi`, `Xác nhận`, `Hủy`.
- **Kiểm chứng Bước 10:** CI #17/#19/#20 từng có widget test lỗi hoặc timeout, dù workflow đôi khi báo success. Đã sửa fixture bất đồng bộ, tách controller trong widget test khỏi singleton và timer. **CI #23 (commit `fb5519b`) đã xác nhận analyzer ✅, 42 unit/widget test ✅, APK arm64 ✅, smoke Android 13 (7/7) ✅.** Chưa kiểm tra SQLite/GPS thật trên Redmi.

## Cây thư mục chính

```text
.
├── .github/workflows/ci.yml
├── ci/{debug.keystore,scripts/*}       # không chỉnh sửa bộ CI
├── integration_test/app_smoke_test.dart # giữ nguyên
├── assets/{images/logo.png,map_styles/}
├── docs/{design/,GPS_SETUP.md,GOOGLE_MAPS_SETUP.md}
├── lib/
│   ├── core/{app_config.dart,router/app_router.dart,theme/app_colors.dart}
│   ├── features/
│   │   ├── fare_meter/fare_calculator.dart         # MỚI Bước 10
│   │   ├── trip/trip_controller.dart               # MỚI Bước 10
│   │   ├── trip/presentation/{trip_page.dart,trip_map_panel.dart}
│   │   ├── map_tracking/{data/,presentation/}
│   │   ├── history/presentation/
│   │   ├── receipt/presentation/
│   │   └── settings/presentation/settings_page.dart
│   ├── shared/
│   └── main.dart
├── test/
│   ├── fare_calculator_test.dart                    # MỚI Bước 10
│   ├── trip_controller_test.dart                    # MỚI Bước 10
│   ├── trip_page_test.dart                          # cập nhật Bước 10
│   └── ...                                         # test cũ
├── pubspec.yaml
└── PROGRESS.md
```

## Dependencies và phiên bản

| Package | Ghim |
|---|---|
| `flutter_riverpod` | `3.5.0` |
| `go_router` | `18.1.4` |
| `google_fonts` | `8.1.0` |
| `fl_chart` | `1.3.1` |
| `qr_flutter` | `4.1.0` |
| `shared_preferences` | `2.5.6` |
| `google_maps_flutter` | `2.19.0` |
| `geolocator` | `14.1.2` |
| `permission_handler` | `12.0.3` |
| `wakelock_plus` | `1.8.0` |
| **`sqflite`** | **`2.4.6`** (Bước 10) |
| `flutter_lints` | `6.0.0` |

Dart SDK `>=3.12.0 <4.0.0`. Flutter CI #16: **3.50.0** stable.

## Quyết định kỹ thuật và rủi ro

- Không dùng Google Directions/Places/Geocoding API; khoảng cách tính cước lấy từ `GpsTracker`, không phải từ Google Maps.
- Snapshot là dữ liệu phục hồi chuyến đang chạy, **không phải bảng `trips` lịch sử hoàn chỉnh**; lưu lịch sử và thống kê thật sẽ làm ở Bước 13.
- Nếu không có GPS/tín hiệu xấu hoặc điện thoại bị hệ thống dừng, quãng đường có thể bị thiếu. UI ghi rõ chỉ là **cước tham khảo**, không có giá trị pháp lý/kiểm định, không thay thế thiết bị thu cước được cấp phép.
- Khi app bị đóng, không tự cộng khoảng cách hoặc thời gian chờ chưa ghi nhận, để tránh cộng phí sai. Mốc phục hồi thực tế bị giới hạn bởi snapshot gần nhất, tối đa khoảng 3 giây nếu timer/SQLite vẫn hoạt động bình thường.
- `sqflite` chỉ mở database trên Android bình thường. CI mock dùng memory; vì vậy phải thử phục hồi SQLite thực tế trên thiết bị.
- Widget test có thể chạy không có GPS/GoogleMap/API; CI vẫn dùng `kCI`. Giữ nguyên workflow, khóa ký debug và smoke test chuẩn.
- Repo public có debug keystore cố định, cần cân nhắc chuyển private; API key vẫn chỉ lưu GitHub Secret.
- Google Maps thật/GPS nền có thể bị giới hạn bởi MIUI; xác minh thực địa và quyền thông báo foreground.

## Kết quả CI

- **CI #16** commit `960bdf5`: 4/4 đạt. https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions/runs/44284562646
- **Bước 10 + 11:** **CI #23 đạt 4/4**, commit ứng dụng `fb5519b`: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions/runs/44317231987. Đã kiểm tra trực tiếp job logs: analyzer không có warning/error (còn lint `info`), 42/42 unit/widget test đạt, APK debug arm64 được build, Android 13 smoke test 7/7 đạt. Issue #1 báo `✅ TẤT CẢ ĐẠT`: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1. APK: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/releases/tag/debug-latest
- **Bước 12 (phần cơ sở): CI #24 đạt 4/4**, commit ứng dụng `f3d8c4b`: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions/runs/44324457199. Job logs: analyzer không warning/error (lint info vẫn còn), **51/51 unit/widget test đạt**, APK debug arm64 build đạt, **Android 13 smoke 7/7 đạt**. APK: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/releases/tag/debug-latest. Chưa thử GPS thật, chưa đối chiếu nội dung đầy đủ Master Prompt Bước 12.
- SHA-1 debug: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.

## Cần thử trên điện thoại

- Redmi Note 12 Pro: Cài đặt → Biểu phí & Phí chờ: sửa phút miễn phí/đơn giá, nhấn Lưu, mở lại xem có giữ số.
- Bật GPS và thử cuốc ở nơi an toàn, không thao tác khi đang lái. Quan sát quãng đường/tốc độ thực, số tiền theo mốc 1,5 km, các bậc km, phí chờ và BOT.
- Tạm dừng để kiểm tra thời gian chờ tăng; tiếp tục để xem trở lại cước theo km; nếu bật auto Waiting, thử tốc độ dưới 3 km/h trong 10 giây và kiểm tra chuyển trạng thái.
- Trong cuốc, chuyển ứng dụng ra nền/tắt màn hình, sau đó ép đóng và mở lại: phải có hộp thoại **“Khôi phục chuyến đang chạy?”**. Kiểm tra số liệu không nhảy thêm giờ/kilômét lúc ứng dụng đóng. Thử chọn Bỏ chuyến cũ.
- Kết thúc chuyến kiểm tra snapshot được xóa, mở lại app không hỏi khôi phục; biên lai có tổng tiền, thời gian, quãng đường, chờ và BOT.
- Do GPS điện thoại có sai số, không sử dụng cước hiển thị để thu tiền khi chưa kiểm chứng.

## Việc tiếp theo

**Ưu tiên hiện tại:** Phần cơ sở Bước 12 đã qua CI #24: analyzer, 51 unit/widget test, APK arm64, 7/7 smoke Android 13. Tiếp theo kiểm tra Redmi và đối chiếu Master Prompt gốc trước khi xác nhận trọn Bước 12. Không triển khai Bước 13 khi chưa có yêu cầu tiếp tục.

## Bước 11 — triển khai xong, CI 4/4 đạt; chờ kiểm thử kết nối thực địa

- `place_search_service.dart`: tìm địa chỉ Nominatim có cấu hình qua HTTPS (mặc định tắt), chặn API Nominatim công cộng; chỉ gọi thủ công, cache 24h/64 câu, tối đa 5 kết quả, giới hạn theo tiến trình 1,2 giây/truy vấn.
- `osrm_route_service.dart`: định tuyến qua máy chủ OSRM HTTPS do nhà vận hành cung cấp (mặc định tắt), chặn demo công cộng, tối đa 3 điểm/3 tuyến, GeoJSON, ETA, danh sách rẽ, cache 10 phút/24 truy vấn.
- Màn Tìm kiếm hỗ trợ chọn tọa độ thật truyền sang Lập tuyến. Màn Lập tuyến dùng OSRM/polyline trên Google Maps, xem các bước rẽ, ước tính cước bằng `FareCalculator.estimate` với cấu hình trên máy.
- Mọi kết quả mẫu được ghi nhãn rõ và vẫn dùng trong CI; không xin Google Maps API key cho widget test.
- Chưa có dẫn đường giọng nói hay theo dõi tiến độ rẽ trực tiếp trên TripPage. BOT, kẹt xe và vị trí GPS không được suy đoán. Khoảng cách tuyến OSRM không thay thế GPS để tính cước đang chạy.
- Cấu hình dịch vụ Nominatim/OSRM HTTPS được phép ngay trên điện thoại qua **Cài đặt → Máy chủ tìm địa chỉ & định tuyến → Lưu máy chủ tuyến**. URL lưu trong SharedPreferences, phục hồi khi mở app, để trống = tắt dịch vụ. Không cần đổi workflow/Google Maps API key. Hướng dẫn chính thức tại `docs/ROUTING_SETUP.md`.
- Bổ sung `test/route_services_test.dart`, `test/route_live_widgets_test.dart` và `test/routing_server_settings_test.dart` dùng phản hồi giả lập, không cần mạng. **CI #23 commit `fb5519b` đạt đủ 4/4.** Hạ tầng Nominatim/OSRM tự quản hoặc được cấp phép và thử nghiệm tuyến thật trên điện thoại vẫn chưa thực hiện; không tuyên bố dịch vụ thực địa đã hoạt động.

## Bước 12 — hoàn thành phần cơ sở, CI #24 đạt 4/4; còn thiếu Master Prompt gốc

- **Tình trạng yêu cầu:** File `MASTER PROMPT.md` của cuộc trao đổi trước không có trong danh sách file repository hoặc tệp dự án truy cập được ở lượt này; **chưa thể xác nhận phạm vi Bước 12 theo nguyên văn Master Prompt**.
- **Phần thực hiện có thể kiểm chứng:** `road_safety/speed_alert_engine.dart` xử lý ngưỡng tốc độ tài xế tự chọn; yêu cầu 3 mẫu liên tiếp vượt >5 km/h, 2 mẫu trở về dưới ngưỡng+1, khử nhiễu/mất GPS, giới hạn tần suất cảnh báo 30 giây.
- `road_safety/speed_alert_controller.dart` lấy dữ liệu GPS đã lọc, từ chối mẫu kém/cũ và lưu cấu hình qua SharedPreferences; không mở thêm API hoặc quyền mới. Mặc định tắt.
- `speed_alert_widgets.dart` hiển thị banner tại Home/Trip và màn Cài đặt `Cảnh báo tốc độ cá nhân` cho tài xế bật/tắt, đặt ngưỡng, lưu lại. Banner luôn ghi rõ đây **không phải giới hạn tốc độ pháp lý**.
- Không dùng `traffic_signs.csv` hay `giao_thong_viet_nam.csv` làm nguồn tốc độ giới hạn tự động do chưa xác minh tính chính thức/độ mới. Biển giới hạn minh họa trên bản đồ vẫn được ghi nhãn dữ liệu mẫu.
- Test mới: `test/speed_alert_engine_test.dart`, `test/speed_alert_widgets_test.dart`; CI dùng GPS/SharedPreferences giả lập, không có Google Maps API key.
- Hướng dẫn và giới hạn tại `docs/SPEED_ALERT_SETUP.md`. **CI #24 đã xác nhận phần cơ sở 4/4 đạt. Chưa xác nhận toàn bộ Bước 12 khi chưa đối chiếu Master Prompt gốc và chưa thử thực địa trên Redmi.**
