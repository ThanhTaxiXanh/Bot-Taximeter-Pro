# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 20/11/2026 (giờ Việt Nam). Repo `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

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
- Snapshot vẫn là dữ liệu khôi phục chuyến đang chạy; Bước 13 tạo bảng `completed_trips` riêng và chỉ xóa snapshot sau khi lưu chuyến hoàn thành thành công. Không được xóa snapshot khi nâng DB v1→v2.
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
- **Bước 13 (lưu lịch sử và thống kê cước GPS): CI #26 đạt 4/4**, commit mã `1a87031`: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions/runs/44447984709. Log kiểm tra trực tiếp: analyzer không lỗi/warning (còn lint info), **56/56 unit/widget test đạt**, APK debug arm64 đạt, **Android 13 8/8 integration đạt**, trong đó 7 smoke chuẩn + 1 SQLite native. APK: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/releases/tag/debug-latest. Chưa kiểm tra upgrade v1→v2/SQLite trên Redmi có dữ liệu cũ và chưa đối chiếu Master Prompt đầy đủ.
- **Bước 14 (biên lai PDF offline): CI #28 đạt 4/4**, commit ứng dụng `88b5a98`: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions/runs/44454638790. Đã đối chiếu log trực tiếp: analyzer không warning/error (còn lint info), **58/58 unit/widget test đạt**, build APK debug arm64 đạt, **9/9 integration Android 13 đạt** (7 smoke, 1 SQLite, 1 PDF). APK: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/releases/tag/debug-latest. Chưa thử in/chia sẻ/lưu PDF trên Redmi thực tế; VietQR vẫn demo.
- **Bước 15 (VietQR offline theo cuốc đã lưu): CI #30 đạt 4/4**, commit mã `2ec236b`: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions/runs/44458349547. Log xác nhận analyzer không warning/error, **66/66** unit/widget test, APK debug arm64 và **9/9** Android 13 integration (7 smoke chuẩn + 1 SQLite native + 1 PDF offline). Bản debug tại https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/releases/tag/debug-latest. Chưa đối chiếu Master Prompt, chưa kiểm tra quét VietQR và tiền ngân hàng thật trên Redmi.
- SHA-1 debug: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.

## Cần thử trên điện thoại

- Redmi Note 12 Pro: Cài đặt → Biểu phí & Phí chờ: sửa phút miễn phí/đơn giá, nhấn Lưu, mở lại xem có giữ số.
- Bật GPS và thử cuốc ở nơi an toàn, không thao tác khi đang lái. Quan sát quãng đường/tốc độ thực, số tiền theo mốc 1,5 km, các bậc km, phí chờ và BOT.
- Tạm dừng để kiểm tra thời gian chờ tăng; tiếp tục để xem trở lại cước theo km; nếu bật auto Waiting, thử tốc độ dưới 3 km/h trong 10 giây và kiểm tra chuyển trạng thái.
- Trong cuốc, chuyển ứng dụng ra nền/tắt màn hình, sau đó ép đóng và mở lại: phải có hộp thoại **“Khôi phục chuyến đang chạy?”**. Kiểm tra số liệu không nhảy thêm giờ/kilômét lúc ứng dụng đóng. Thử chọn Bỏ chuyến cũ.
- Kết thúc chuyến kiểm tra snapshot được xóa, mở lại app không hỏi khôi phục; biên lai có tổng tiền, thời gian, quãng đường, chờ và BOT.
- Do GPS điện thoại có sai số, không sử dụng cước hiển thị để thu tiền khi chưa kiểm chứng.

## Việc tiếp theo

**Bước 24 — cổng bàn giao bản debug và rào chắn hồi quy**: hoàn thiện hồ sơ bàn giao, cập nhật checklist CI #43, thêm test bảo vệ package/7 route/Maps không Map ID/GPS profile/làm tròn. **Trước bước 24, CI #43 commit `c473bb4` đạt 4/4 theo Issue #1 và các job GitHub Actions.** Flutter 3.50.1 stable. **CI của commit Bước 24 chưa được xác minh**; không khẳng định kết quả thiết bị Redmi. Xem [`docs/DEBUG_RELEASE_GATE_STEP24.md`](docs/DEBUG_RELEASE_GATE_STEP24.md) và [checklist nghiệm thu](docs/ACCEPTANCE_STEP23.md). **Bước tiếp theo: 25 — chỉ xử lý phản hồi/lỗi có bằng chứng**, sau lệnh `TIẾP TỤC` và xác nhận CI.

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

## Bước 13 — lưu lịch sử/thu nhập tham khảo đã triển khai, CI #26 đạt 4/4

- `TaximeterDatabase` nâng `bot_taximeter.db` từ v1 lên v2, thêm `completed_trips` và chỉ mục thời gian, giữ nguyên `trip_snapshots` để khôi phục chuyến cũ.
- `TripController.complete()` ghi một `CompletedTrip` idempotent theo ID bắt đầu chuyến trước khi xóa snapshot. Lưu lỗi thì giữ snapshot, tài xế có thể thử lại. Không ghi chuyến khi Bỏ chuyến cũ.
- `HistoryPage` thay doanh thu mẫu bằng số liệu từ `CompletedTripStore`, lọc hôm nay/7 ngày/30 ngày và vẽ biểu đồ 7 ngày. Không nhận tiền thật, không suy đoán dữ liệu thanh toán.
- Biên lai đọc bản ghi thực với ID, mốc thời gian, km, phút chờ, BOT và cước GPS; các trường chưa có ghi “Chưa ghi nhận” thay vì hiển thị dữ liệu khách mẫu.
- `test/completed_trip_store_test.dart`, `test/history_page_test.dart` mới và `integration_test/completed_history_test.dart` kiểm tra SQLite native trên máy ảo; giữ nguyên smoke test chuẩn.
- Hướng dẫn thử an toàn và giới hạn tại `docs/HISTORY_STORAGE.md`. **CI #26 đã xác nhận 56/56 unit/widget test, APK arm64, 8/8 integration Android 13 (gồm SQLite native).** Chưa thử nâng cấp SQLite v1→v2 trực tiếp trên Redmi, chưa xác nhận thanh toán thật/PDF, và vẫn thiếu Master Prompt gốc để đối chiếu phạm vi.

## Bước 14 — phần biên lai PDF đã triển khai, CI #28 đạt 4/4

- `receipt_pdf_service.dart` tạo PDF A4 offline từ `ReceiptPdfData` chuyến đã lưu Bước 13; không cho xuất bản mẫu. Dựng chữ Việt bằng Flutter Canvas thành ảnh trước khi chèn PDF để tránh tải font từ mạng. Nội dung PDF là ảnh, không tìm kiếm được văn bản.
- `ReceiptPage`: **In biên lai** gọi hộp thoại in Android; **Chia sẻ** và **Xuất PDF** gọi trình chia sẻ/lưu tệp Android qua package `printing`. Không tự xác nhận đã lưu, in hoặc gửi file; thao tác chỉ phát sinh khi tài xế bấm. Không in/đưa VietQR demo thành thanh toán thật.
- Mỗi biên lai PDF ghi “CƯỚC GPS THAM KHẢO”, “KHÔNG PHẢI HÓA ĐƠN · CHƯA KIỂM ĐỊNH”; không thu thập thêm số điện thoại, địa chỉ khách hay trạng thái thanh toán.
- Bổ sung `pdf: 3.13.1` và `printing: 5.15.0` vào pubspec, `test/receipt_pdf_test.dart` và `integration_test/receipt_pdf_test.dart`. Giữ nguyên CI, smoke test chuẩn, package Android và SHA-1.
- Hướng dẫn thử: `docs/RECEIPT_PDF.md`. **CI #28 commit `88b5a98` đạt đủ analyzer, 58/58 unit/widget, APK arm64 và Android 13 9/9 integration (7 smoke chuẩn, 1 SQLite native, 1 PDF offline).** Chưa thử xuất/in/chia sẻ trên Redmi; chưa đối chiếu Master Prompt gốc để xác định toàn bộ phạm vi Bước 14.

## Bước 15 — phần mã VietQR offline đã triển khai, CI #30 đạt 4/4

- Tham khảo cấu trúc VietQR/NAPAS247 và EMVCo: `vietqr_transfer_payload.dart` tạo payload TLV với ngân hàng BIN 6 chữ số, số tài khoản, số tiền VND và CRC16/CCITT-FALSE; không gọi API, không gửi thông tin đến ngân hàng, không tạo giao dịch tự động.
- `SettingsPage` có ô BIN ngân hàng và cờ **Cho phép tạo VietQR chuyển khoản** mặc định **TẮT**. Bật chỉ khi BIN, số tài khoản và tên người nhận hợp lệ ở mức kiểm tra định dạng. Không tự khẳng định ngân hàng/tài khoản đã được xác minh.
- `CompletedTrip.receiptSnapshot` có `amountVnd` nguyên gốc từ SQLite; không suy đoán tiền bằng cách parse chữ cước. `ReceiptTransferPanel` chỉ tạo QR sau thao tác **Hiển thị QR chuyển khoản** trên một chuyến đã lưu. Biên lai mẫu vẫn hiện mã DEMO và không tạo QR chuyển tiền.
- QR chuyển khoản **không** xác nhận đã thanh toán, không sửa dữ liệu doanh thu, không xuất hóa đơn hay lưu mật khẩu/OTP. Tài xế phải xác minh tiền vào bằng kênh ngân hàng riêng.
- Kiểm thử mới: `test/vietqr_transfer_test.dart`, `test/vietqr_panel_test.dart`, mở rộng `test/completed_trip_store_test.dart`; hướng dẫn `docs/VIETQR_TRANSFER.md`.
- **CI #30 (commit ứng dụng `2ec236b`) đã đạt 4/4 theo log:** analyzer không warning/error (lint info vẫn còn); **66/66 unit/widget test**; build APK debug arm64; **9/9 integration Android 13** (7 smoke chuẩn, 1 SQLite native, 1 PDF offline). Kiểm thử QR trên Android hiện chỉ là unit/widget, **chưa thử quét mã bằng ứng dụng ngân hàng thực tế trên Redmi**. Thiếu `MASTER PROMPT.md` gốc nên chưa thể gọi toàn bộ phạm vi Bước 15 hoàn tất.

## Bàn giao 19/11/2026

- Biên bản đầy đủ: [`docs/HANDOFF_2026-11-19.md`](docs/HANDOFF_2026-11-19.md).
- Commit mã ứng dụng gần nhất: `2ec236ba1a6effdcea8321f8c536a04a178af6fd`; tài liệu bàn giao chỉ thay đổi Markdown, không khởi động build APK mới vì workflow bỏ qua `**.md`.
- Mốc xác minh: **CI #30 đạt 4/4**; Issue #1 báo “TẤT CẢ ĐẠT”.
- Việc chưa xác minh: GPS/bản đồ thật, nâng cấp SQLite có dữ liệu cũ trên Redmi, máy chủ Nominatim/OSRM được phép, chia sẻ/in PDF trên Android thật, VietQR quét được trên ngân hàng thật. Cước GPS **chỉ tham khảo**.


## Nghiệm thu thiết bị & đối chiếu MASTER PROMPT gốc — 19/11/2026

**Nguồn xác nhận:** Người dùng báo cáo đã trực tiếp thử bản APK trên Redmi Note 12 Pro ngày 19/11/2026. Đây là kết quả nghiệm thu thủ công do người dùng cung cấp, không phải log thiết bị được thu thập độc lập. Không có giao dịch ngân hàng được thực hiện; không chứng minh tiền đã vào tài khoản.

### Kết quả kiểm thử thực tế do người dùng xác nhận

- [x] Cài đè APK, không xóa dữ liệu ứng dụng và SQLite cũ.
- [x] Kiểm tra GPS, quãng đường, cước theo km, BOT và phí chờ.
- [x] Kiểm tra tạm dừng, tiếp tục và khôi phục chuyến sau khi đóng ứng dụng.
- [x] Kiểm tra lịch sử, tạo PDF tiếng Việt, in và chia sẻ tệp.
- [x] Quét VietQR bằng ứng dụng ngân hàng, đối chiếu người nhận và số tiền; **không chuyển khoản**.

Bộ kiểm thử CI gần nhất có thể xác minh vẫn là **CI #30**, commit `2ec236ba1a6effdcea8321f8c536a04a178af6fd`: analyzer đạt, 66/66 unit/widget, APK debug arm64, 9/9 integration Android 13.

### Đối chiếu Master Prompt gốc (tệp thuộc Project ChatGPT)

- Master Prompt mục **10** định nghĩa **14 bước**; không có định nghĩa Bước 15 hay Bước 16. Số thứ tự Bước 13–15 trong quá trình triển khai hiện tại là cách tách nhỏ công việc, **không trùng hoàn toàn** với lộ trình gốc.
- **Bước 12 gốc (mục 6B):** yêu cầu `speed_rules.dart`, `SpeedLimitEngine`, `RoadContextProvider` (OSM/Overpass), ghi đè biển/ngưỡng, cảnh báo theo bậc và unit test pháp lý. Repo mới có `features/road_safety` để cảnh báo theo **ngưỡng cá nhân**, chưa có bằng chứng triển khai hệ quy tắc pháp lý đầy đủ. Không được hiển thị ngưỡng cá nhân như giới hạn tốc độ hợp pháp.
- **Bước 13 gốc:** gộp lưu lịch sử SQLite, thống kê/biểu đồ thật, VietQR offline, **danh sách/cache ngân hàng** và PDF. Mã hiện đã chia thành Bước 13 (lịch sử), 14 (PDF), 15 (VietQR), nhưng chưa thấy triển khai `banks` cache/seed và tải danh sách BIN theo yêu cầu gốc; cần xác minh trước khi tuyên bố đạt đầy đủ mục 13 gốc.
- **Bước 14 gốc:** hoàn thiện **SOS, cảnh báo, câu chào LED, tối ưu pin, rà soát chi phí Google, README**. Theo cây file hiện tại và PROGRESS chưa có cơ sở xác nhận hoàn thành toàn bộ; cần lập danh sách việc còn lại khi được phép triển khai.
- **Khác biệt package cần giữ nguyên:** Master Prompt có chỉ dẫn Google Maps theo package `vn.bottaximeter.pro`, trong khi package Android đã bàn giao và kiểm thử là `vn.bottaximeter.bot_taximeter_pro`. **Không đổi package**; khi rà soát khóa Maps phải dùng package thực tế của APK cùng SHA-1 hiện hành, không sao chép nguyên ví dụ cũ.
- File `MASTER PROMPT.md` đã có trong tệp của Project ChatGPT và được đọc để đối chiếu, nhưng **chưa được tìm thấy trong thư mục gốc của repository GitHub** khi kiểm tra `main`.

**Kết luận:** Ghi nhận Bước 15 phần cơ sở đã đạt CI và 5/5 thử nghiệm thủ công được báo cáo. Chưa xác nhận toàn bộ phạm vi Master Prompt gốc. **Dừng ở mốc bàn giao Bước 15; không triển khai Bước 16 nếu chưa có lệnh “TIẾP TỤC” và phạm vi được chốt.** Cước GPS vẫn chỉ mang tính tham khảo, chưa được kiểm định pháp lý.


## Bước 16 — kiểm toán khoảng trống (19/11/2026)

- Đã đối chiếu Master Prompt gốc trong Project ChatGPT với cây nguồn GitHub `main` và các file mã/CI hiện hành.
- Biên bản chi tiết: [`docs/FEATURE_GAP_AUDIT_2026-11-19.md`](docs/FEATURE_GAP_AUDIT_2026-11-19.md); 12 nhóm khoảng trống/chưa xác minh, chia P0/P1/P2.
- P0: quy tắc giới hạn tốc độ pháp lý (mục 6B) còn thiếu; SOS hiện là hộp thoại bản mẫu, chưa có lệnh gọi hoặc gửi vị trí.
- P1: dẫn đường GPS trực tiếp, dữ liệu ngân hàng BIN cache/seed, LED toàn màn hình, SQLite chuyến chi tiết.
- P2: giọng nói, lưu tuyến, thống kê so sánh, cảnh báo kẹt xe, hoàn thiện README và kiểm toán chi phí Maps.
- Mã và CI **không thay đổi**. Bước 17 chỉ là **đề xuất**; chờ yêu cầu `TIẾP TỤC`.


## Bước 17 — engine quy tắc tốc độ Dart thuần (19/11/2026)

- Thêm `lib/features/speed_limit/speed_rules.dart`: 16 quy tắc Điều 6 theo 4 nhóm xe, khu đông/ngoài khu đông dân cư, 2 kiểu đường. Mỗi hàng có căn cứ, điều khoản và ngày hiệu lực. Nguồn tham khảo Thông tư 38/2024, VBHN 74/2026, QCVN 41:2024, Nghị định 168/2024 đã sửa bởi 238/2026.
- Thêm `lib/features/speed_limit/speed_limit_engine.dart`: `RoadContext`/`SpeedLimitResult`, ưu tiên manual > posted > rule > unknown. OSM chưa xác minh và khu vực suy đoán chỉ tham khảo, không cấp quyền cảnh báo. Thiếu ngữ cảnh trả `--`; cao tốc không tự áp giá trị 120/60.
- Thêm `test/speed_limit_rules_test.dart` kiểm tra mọi tổ hợp Điều 6, thứ tự ưu tiên, dữ liệu chưa xác minh, mức cao tốc, ngưỡng phân loại 5/10/20/35 km/h. Chưa phát âm/rung hoặc đưa ra nhận định vi phạm.
- Thêm `docs/SPEED_LIMIT_LEGAL_BASE_2026-11-19.md` mô tả căn cứ và giới hạn. Chưa thêm provider OSM/Overpass, UI, xác thực GPS 3 giây/15 giây (dành cho Bước 18).
- Không thay đổi code hiện hành của GPS/cước/SQLite/PDF/VietQR, package Android, theme, route và CI.
- **Chưa xác minh CI cho commit Bước 17. CI #30 vẫn là mốc đạt trước đó.**
- **Bước tiếp theo: 18. Dừng, chờ lệnh TIẾP TỤC.**


## Bước 18 — tích hợp biển tốc độ và ngữ cảnh OSM tham khảo (19/11/2026)

- Đã xác nhận trước khi thực hiện: **CI #31, commit `688872a`, đạt 4/4** (analyze, unit/widget, build APK arm64, Android 13 integration).
- Thêm `lib/features/speed_limit/road_context_provider.dart`: `RoadContextProvider` tra cứu OSM qua **Overpass HTTPS được tài xế cấu hình**, không mặc định endpoint; chỉ chạy khi tài xế bấm, không gọi ở CI, cache RAM khoảng 200 m/64 ô, giới hạn tối thiểu 10 giây giữa các request mới. Không cho OSM giả định giới hạn hợp pháp.
- `RoadSpeedController` dùng chung hai màn, cài đặt tay có phạm vi khoảng 200 m hoặc đến khi tài xế đổi, lưu SharedPreferences. Nguồn OSM chưa xác minh hoặc thiếu khu vực/kiểu đường phải để `~` hoặc `--`, `canAlert=false`; không nhận dạng tự động biển qua camera.
- Thêm `lib/features/speed_limit/road_speed_panel.dart` hiển thị tốc độ GPS và biển, sheet chọn khu vực/kiểu đường, nhập biển và máy chủ OSM. Cảnh báo **trực quan** chỉ sau 3 giây vượt liên tục khi GPS tốt, 2 xung cách ≥15 giây, không bật âm thanh/rung trong bước này.
- Chỉ sửa `home_page.dart` và `trip_map_panel.dart` để APK thật dùng panel mới; CI/widget test giữ `HomeSpeedPanel` mẫu cho tương thích luồng cũ.
- Thêm `test/road_context_provider_test.dart` với kiểm thử nguồn, cache, 3s/15s và widget. Tổng cộng **5 Dart file** liên quan; không file nào >300 dòng. Tài liệu `docs/SPEED_LIMIT_STEP18.md` ghi rõ giới hạn, cách thử và nguyên tắc tránh cảnh báo sai.
- **Còn thiếu:** âm báo/rung kiểm soát thực tế; định danh biển theo đoạn và hướng, kiểm chứng thực địa; không khẳng định app xác định chính xác giới hạn hợp pháp trên mọi tuyến. Không ảnh hưởng cước, BOT, snapshot/SQLite, PDF/VietQR.
- **CI Bước 18 chưa xác nhận tại thời điểm commit. Bước tiếp theo: 19, chờ người dùng TIẾP TỤC.**


## Sửa lỗi CI #32 trước Bước 19 (19/11/2026)

- CI #32 tại commit `8f4bf18`: GitHub Actions workflow hiện trạng có `conclusion=success` do một bước tiếp tục khi lỗi; **Issue #1 phản ánh flutter test lỗi**. Phân tích tĩnh, APK, Android integration đạt; `flutter test` có **1 lỗi widget**.
- Log: `test/road_context_provider_test.dart`, test `Biển mặc định --, nhập thủ công chỉ khi chủ động lưu`; `Expected <80>, Actual <null>`, cảnh báo tap offscreen tại tọa độ y=1382 và y=1477 ngoài `Size(440,1000)`.
- Sửa đúng test này: dùng `tester.widget<ActionChip>(...).onPressed!.call()`, `SwitchListTile.onChanged!(true)`, `FilledButton.onPressed!.call()` và pump để kiểm tra logic mà không phụ thuộc scrolling/viewport giả lập. **Không thay đổi mã nguồn ứng dụng.**
- CI mới **chưa xác minh ở thời điểm commit**. Bước 19 chưa thực hiện; phải xác nhận `flutter test` thực sự đạt trước khi bước tiếp.


## Bước 19 — SOS khẩn cấp có xác nhận (19/11/2026)

- Điều kiện mở: **CI #33 của bản sửa Bước 18 `842af5a` đã đạt 4/4** theo GitHub Actions và Issue #1: analyze, unit/widget, APK arm64, Android 13 integration.
- Đối chiếu Master Prompt gốc mục 8: **SOS xác nhận → mở số gọi khẩn cấp mặc định 113 / số cấu hình → chia sẻ vị trí bằng `share_plus`**. Không tự gọi hoặc gửi vị trí.
- Thêm `lib/features/sos/sos_service.dart`: kiểm tra số điện thoại (không chấp nhận dấu lệnh/URL), lưu `sos_phone` vào `SharedPreferences`, mở `tel:` bằng `url_launcher` ở chế độ externalApplication, mở bảng chia sẻ vị trí bằng `share_plus`; không dùng `CALL_PHONE`. Chỉ đọc fix GPS đã lọc, không cho dữ liệu mock, quá 15 giây hoặc độ chính xác >25m; không thu thập lịch sử GPS mới.
- Thêm `lib/features/sos/sos_widgets.dart`: hộp thoại SOS với nút Gọi và Chia sẻ vị trí **mỗi nút có xác nhận phụ riêng**, xử lý không có GPS/ứng dụng hỗ trợ; `SosSettingsCard` lưu số SOS riêng trong Cài đặt.
- Chỉ sửa `trip_page.dart` để nút SOS mở chức năng thật; `settings_page.dart` để hiện cấu hình SOS; `test/trip_page_test.dart` kiểm tra không thực hiện khi chưa xác nhận, xử lý GPS cũ/yếu, số hợp lệ và test bằng backend giả không gọi plugin trong CI.
- `pubspec.yaml` thêm chính xác `url_launcher: 6.3.3` và `share_plus: 13.3.1`; CI #34 phát hiện share_plus 11.1.0 xung đột `win32 ^5.5.3` với `wakelock_plus 1.8.0` (`win32 ^6.0.1`); đã sửa thành share_plus 13.3.1 để giải quyết dependency mà không đổi wakelock hay CI. `docs/SOS_STEP19.md` ghi cách thử an toàn khi xe đứng yên.
- Giữ nguyên package Android, debug keystore, CI, 7 route, cước/BOT/chờ, SQLite, PDF/VietQR, Maps và module tốc độ. **Chỉ có 5 tệp Dart** liên quan, mỗi tệp dưới 300 dòng.
- **CI cho commit Bước 19 chưa được kiểm chứng tại thời điểm commit.** Không tuyên bố SOS đã thử với trình gọi/ứng dụng chia sẻ thực trên Redmi khi chưa có nghiệm thu thiết bị.
- **Bước tiếp theo: 20**, danh sách/cache ngân hàng VietQR (đề xuất), chờ người dùng `TIẾP TỤC` sau khi xem CI Bước 19.


### Sửa phụ thuộc CI #34 của Bước 19 (19/11/2026)

- **CI #34 commit `9773e2d` chưa đạt:** trong bước `flutter create`/pub resolution, `share_plus 11.1.0` phụ thuộc `win32 ^5.5.3`, còn `wakelock_plus 1.8.0` phụ thuộc `win32 ^6.0.1`. Các bước analyze/test/build/Android integration chưa chạy, không có APK mới từ #34.
- Chỉ đổi `pubspec.yaml`: `share_plus: 11.1.0` → **`share_plus: 13.3.1`**, phiên bản yêu cầu `win32` 6; vẫn dùng `url_launcher: 6.3.3` và `wakelock_plus: 1.8.0`.
- Cập nhật `docs/SOS_STEP19.md` và `PROGRESS.md` cho đúng thực tế, **không** thay mã SOS, GPS/cước, SQLite/PDF/VietQR, package Android, debug keystore hoặc workflow. CI của commit sửa phụ thuộc **chưa được xác minh**.


### Sửa lỗi CI #35 của Bước 19 (19/11/2026)

- CI #35, commit `bb2485e`: `flutter pub get` đã thành công nhưng `flutter analyze`/unit-widget/build APK không đạt; báo cáo Issue #1 có 3 lỗi cùng nguyên nhân từ `lib/features/sos/sos_widgets.dart:3`.
- Import sai `../../settings/presentation/settings_widgets.dart` từ thư mục `lib/features/sos/` trỏ sang `lib/settings/` không tồn tại. Sửa thành **`../settings/presentation/settings_widgets.dart`**, đúng đường dẫn tới `lib/features/settings/presentation/settings_widgets.dart`; các lỗi không tìm thấy `SettingsSection` và `SettingsField` là hệ quả của import hỏng.
- Chỉ sửa **1 dòng trong 1 tệp Dart** và cập nhật `PROGRESS.md`. Không sửa chức năng SOS, dependencies, khóa debug, workflow, GPS/cước, SQLite/PDF/VietQR, 7 route hay màn hình cũ.
- **Chờ CI của commit sửa lỗi:** chỉ xác nhận thành công sau khi đọc Issue #1 và log đúng SHA. Chưa mở Bước 20.


## Bước 20 — danh sách ngân hàng VietQR và cache SQLite v3 (19/11/2026)

- Kiểm tra điều kiện đầu vào: **CI #36 cho commit `f66f3be` đạt 4/4** theo GitHub Actions và Issue #1; Bước 19 SOS giữ nguyên.
- Đối chiếu Master Prompt gốc mục 8: danh sách ngân hàng + mã BIN từ `https://api.vietqr.io/v2/banks` khi online, cache vào bảng SQLite `banks`, có JSON seed offline trong `assets/`. Xác minh định dạng API `code: "00"`, `data`, `bin`, `shortName`, `transferSupported` qua tài liệu VietQR.
- Thêm `lib/features/receipt/data/vietqr_bank_repository.dart`: model `VietQrBank`, kho nhớ và SQLite, kiểm tra cấu trúc API, BIN 6 số, loại bỏ mục không hỗ trợ chuyển tiền, loại trùng BIN, danh sách hợp lệ tối thiểu 5 ngân hàng. Mặc định đọc cache; cache rỗng thì đọc seed và ghi vào SQLite. Tải HTTPS chỉ khi người dùng bấm, không gọi mạng trong CI. Cập nhật thất bại giữ cache cũ bằng transaction SQLite.
- Nâng `lib/features/history/data/taximeter_database.dart` từ **v2 lên v3**, `onCreate` tạo bảng `banks`, `onUpgrade` thêm bảng nếu <3. Vẫn giữ bảng `trip_snapshots`, `completed_trips`, khóa debug, đường dẫn DB `bot_taximeter.db`; không xóa dữ liệu.
- Thêm `assets/data/vietqr_banks_seed.json` chứa **18 ngân hàng/BIN phổ biến** đối chiếu dữ liệu VietQR; đăng ký trong `pubspec.yaml` (không thêm dependency).
- Thêm `lib/features/receipt/presentation/vietqr_bank_picker.dart` chọn/lọc tên hoặc BIN và nút làm mới mạng có chủ ý; sửa `settings_page.dart` để chọn tên và BIN vào hai ô hiện hữu. **Chưa lưu ngay**: phải bấm `Lưu cài đặt`; chủ tài khoản và số TK không bị ghi đè. Không tự bật QR và không đổi payload VietQR offline.
- Thêm `test/vietqr_bank_repository_test.dart` kiểm tra seed/cache offline, không tự gọi API, cập nhật thành công/thất bại giữ cache, phân loại BIN, trùng, ngân hàng không hỗ trợ, widget chọn ngân hàng giả lập. **Tổng cộng 5 Dart file**, mỗi file không quá 300 dòng.
- **Cần thử trên điện thoại:** cài đè APK (không gỡ ứng dụng) và kiểm tra migration SQLite v2→v3 giữ snapshot/lịch sử; chọn ngân hàng, đối chiếu đúng BIN/số tài khoản/chủ TK bằng ứng dụng ngân hàng; dùng offline mở lại vẫn có danh sách; làm mới qua mạng chỉ khi cần; QR vẫn không báo đã nhận tiền. Chưa có integration test native riêng cho bảng banks trên thiết bị.
- **CI của commit Bước 20 chưa được xác minh tại thời điểm ghi.** Bước tiếp theo: **21**, chỉ sau yêu cầu `TIẾP TỤC`, ưu tiên sửa lỗi CI nếu phát sinh.


## Bước 21 — màn hình LED chào khách (19/11/2026)

- **Điều kiện:** Đã đọc Issue #1 và jobs của CI #37 commit `3b6b26d`: **4/4 đạt** (analyze, flutter test, APK debug arm64, Android 13). Không cần sửa Bước 20.
- Theo **Master Prompt mục 8**, LED là màn hình chữ lớn toàn màn hình cho khách nhìn, mở từ Cài đặt (phần tính năng cuối). Không thêm route GoRouter (vẫn 7 route), không đổi package hay manifest.
- Thêm `lib/features/settings/presentation/led_greeting_page.dart`: màn `LedGreetingPage` riêng che giao diện thông thường, nền navy/cyan neon, chữ lớn giữa màn dùng `FittedBox.scaleDown` để vừa cả màn nhỏ và ngang; nút `Đóng màn hình LED` ở phía trên. Các cỡ `Nhỏ/Vừa/Lớn` quy đổi cỡ chữ gốc 64/88/120; chuỗi dài tự co. Không tự phát nhạc, không cần camera/GPS/mạng.
- Chữ LED là **bản xem trước** từ ô `Câu chào LED` và lựa chọn `Kích thước chữ` đang hiển thị. Nếu chưa lưu, chỉ hiện tạm; **không tự ghi SharedPreferences**. Cài đặt vẫn lưu bằng nút `Lưu cài đặt` hiện hữu với keys `led_greeting`, `font_size` như trước. Chuỗi được bỏ ký tự điều khiển và giới hạn 120 ký tự hiển thị; trống dùng `Xin chào quý khách!`; không thay đổi dữ liệu gốc.
- Chỉ thêm **2 dòng** trong `settings_page.dart` (import và nút mở LED) để giữ tệp ≤300 dòng, không thay bố cục cài đặt và các nút cũ. Tạo `test/led_greeting_test.dart`: logic chuẩn hóa/cỡ chữ, màn từ Cài đặt và nút đóng, bản xem trước không tự lưu. Tổng cộng **3 tệp Dart** có thay đổi và 1 tài liệu; không thêm dependency.
- Giữ nguyên phần cước, GPS, báo tốc độ, SOS, SQLite v3, cache ngân hàng VietQR, QR/PDF, debug signing và workflow CI.
- **Cần thử trên điện thoại:** cài đè bản debug sau khi CI đạt; khi xe đỗ, thử hiển thị từ Cài đặt, nhập lời chào tiếng Việt có dấu, thử 3 cỡ chữ và xoay dọc/ngang; quay lại bằng nút Đóng và phím Back, kiểm tra `Lưu cài đặt` không bị tác động. Không thao tác với điện thoại khi đang lái.
- **CI commit Bước 21 chưa xác minh tại thời điểm ghi**. Bước kế tiếp chỉ sau lệnh `TIẾP TỤC` và xác nhận CI.


### Sửa lỗi CI #38 — test màn LED (19/11/2026)

- Đã xác nhận Issue #1 và GitHub Actions #38 tại commit `3aa4318`: **flutter analyze đạt, flutter test lỗi 1 ca (104 ca đạt), build APK và Android 13 đạt**. Không dựa vào workflow `conclusion=success` do `flutter test` được đặt `continue-on-error`.
- Nguyên nhân: `test/led_greeting_test.dart`, ca **LED từ Cài đặt hiển thị lời chào lưu trên máy và đóng được**, dùng `find.text('Chào mừng lên Taxi Xanh')` với `findsOneWidget`; thực tế cùng chuỗi ở ô TextField và Text LED, thành 2 widget. Đây là lỗi chọn Finder, không phải lỗi tính năng LED.
- Sửa **chỉ bài test**: lấy `Text` bằng key `led_message`, kiểm tra `text.data` và `fontSize=120`. Giữ nguyên thao tác đóng, kiểm chứng `SharedPreferences`, không sửa mã ứng dụng.
- Chỉ thay **1 tệp Dart** (<300 dòng) và `PROGRESS.md`; CI của commit sửa lỗi **chưa được xác minh**. **Chưa thực hiện Bước 22**, phải chờ xác nhận CI kế tiếp đạt 4/4.


### Sửa CI #39 — đợi animation đóng màn LED (19/11/2026)

- Đã đọc Issue #1 và log job của **CI #39 commit `dd345f4`**: workflow báo `success` nhưng **flutter test còn 1 ca lỗi**, các phần analyze, APK arm64 và Android 13 đều đạt. Lỗi `test/led_greeting_test.dart:54`: sau khi nhấn nút Đóng, `find.byType(LedGreetingPage)` vẫn tìm thấy 1 widget.
- Nguyên nhân kỹ thuật: bài test chỉ `pump()` và `pump(350 ms)` trước khi kỳ vọng route đã bị dỡ; thời gian chuyển cảnh của `MaterialPageRoute` có thể khác thời gian cố định trong CI. Đổi thành `await tester.pumpAndSettle()` để chờ **toàn bộ animation pop** kết thúc rồi mới kiểm tra màn LED đã biến mất và Settings vẫn còn.
- **Chỉ sửa 1 tệp Dart test** (không thay code ứng dụng), cập nhật `PROGRESS.md`. Không thay SOS, GPS, cước, SQLite v3, VietQR, PDF, chữ LED, package, debug signing, route, CI workflow hoặc cấu hình khác. **Chưa thực hiện Bước 22**; bắt buộc xác minh kết quả CI commit này trước.


## Bước 22 — tối ưu pin, Google Maps và README (19/11/2026)

- **Điều kiện mở bước:** Đã đọc Issue #1 và CI #40 (`c0abdce`) đúng SHA, **flutter analyze, unit/widget, build APK arm64 và Android 13 đều đạt**. Bước 21 hoàn tất kiểm thử tự động.
- Đã đọc Master Prompt gốc `MASTER PROMPT.md` mục 3 (tránh Google API tính phí và Map ID), mục 6 (GPS foreground/wakelock), mục 10.14 (tối ưu pin, rà soát chi phí Google, README). Đối chiếu mã thực tế `SharedMapView`, `GpsTracker`, `main.dart`, `README.md` và hướng dẫn Google hiện có.
- **Giảm tải GPS Home** trong `lib/features/map_tracking/data/gps_tracker.dart`: `GpsPowerPolicy` sử dụng `intervalDuration=5s`, `distanceFilter=10m`, `maxUpdateAge=10s`, accuracy `high` khi chỉ bật GPS xem trước; **khi chuyến đang chạy giữ nguyên** `bestForNavigation`, 1s, 0m, max age 5s, foreground notification và wakelock. Bộ lọc GPS/Haversine và fare engine không đổi.
- **Dừng GPS xem trước khi app paused** trong `lib/main.dart` qua `WidgetsBindingObserver`, chỉ khi `isTracking=true`, không khởi động GPS, không có `tripActive` và `TripController.instance.isActive=false`. Dịch vụ GPS của chuyến không bị dừng khi app ra nền. Khi trở lại Home, người dùng có thể bật xem trước bằng chip GPS.
- Mở rộng `test/gps_tracker_test.dart` kiểm tra cả hai profile interval/distance/age và 6 trường hợp quyết định dừng hoặc không dừng preview; không gọi GPS, mạng hay plugin Android trong CI. **3 tệp Dart có thay đổi**, mỗi file ≤300 dòng.
- Đã soát `lib/shared/shared_map_view.dart`: dùng `google_maps_flutter`, JSON style tối/sáng, traffic và buildings từ SDK, **không mapId**; không dùng Google Directions/Places/Geocoding/Routes/Static Maps/Map Tiles hay 3D SDK. Google hiện niêm yết SKU Maps SDK miễn phí không giới hạn, **Map ID làm phát sinh Dynamic Maps SKU tính phí**. Nguồn chính thức: https://developers.google.com/maps/billing-and-pricing/pricing ; https://developers.google.com/maps/documentation/android-sdk/map-ids/get-map-id . Không cam kết hóa đơn bằng 0; giá có thể đổi.
- Cập nhật `docs/GOOGLE_MAPS_SETUP.md`, thêm `docs/BATTERY_MAPS_AUDIT_STEP22.md`: giới hạn API key theo ứng dụng Android/package đúng `vn.bottaximeter.bot_taximeter_pro` + SHA-1 debug từ Issue #1, giới hạn chỉ Maps SDK for Android, Billing Budget Alerts, quota/giám sát theo SKU, lưu ý alert không tự ngắt phí. **Không sửa/tiết lộ key, không sửa .github/, ci/, debug signing**. Cập nhật `README.md` từ một dòng thành hướng dẫn tổng thể cho người dùng chỉ có điện thoại.
- Không thay logic cước/làm tròn/BOT, GPS filter, SQLite v3, VietQR/PDF, SOS, LED, 7 route, Android package, signing, CI. Không thêm dependencies.
- **Cần nghiệm thu Redmi thực tế:** so sánh GPS Home khi xem/ra nền/quay lại và GPS chuyến đang chạy khi khóa màn hình; đo pin thực tế (chưa xác nhận), đảm bảo không mất quãng đường hoặc chuyến; kiểm tra Cloud Billing/Maps API key và SHA-1 từ bản APK cài đè. **CI của commit Bước 22 chưa được xác minh** tại thời điểm ghi.
- **Bước tiếp theo:** 23 (đề xuất nghiệm thu tổng thể), chờ `TIẾP TỤC` và CI Bước 22 4/4; sửa lỗi CI trước nếu có.


## Bước 23 — kiểm thử hồi quy, nghiệm thu tổng thể (19/11/2026)

- **Điều kiện mở bước:** GitHub HEAD `3669dd4`; Issue #1 và từng job CI #41 xác nhận **4/4**: analyze, unit/widget, APK arm64, Android 13. Không có lỗi CI phải sửa trước khi mở bước.
- **Đối chiếu Master Prompt gốc:** mục 1B (báo cáo CI thật và kiểm thử Android), mục 2 (một bước/lượt, tối đa 5 Dart ≤300 dòng, tiến độ), mục 3 (Google Maps không phí), mục 10 (GPS, cước, lịch sử, VietQR, PDF, SOS, LED, tối ưu pin). Lộ trình gốc kết thúc ở mục 14; **Bước 23 là đợt nghiệm thu bổ sung của dự án, không phải một mục mới trong Master Prompt**.
- Thêm hàm `TaximeterDatabase.openAtPath(path)` vào `lib/features/history/data/taximeter_database.dart` để đưa **chính hàm schema v3/onUpgrade** cho test sử dụng tại đường dẫn DB độc lập. Hàm `instance` vẫn mở `bot_taximeter.db`; giữ nguyên `version: 3` và mọi SQL v1→v2→v3. Không xóa hay sửa SQLite thực của tài xế.
- Thêm `integration_test/sqlite_upgrade_test.dart` chạy trên SQLite native Android: tạo DB cũ v1/v2 riêng, ghi snapshot `waiting`, ở v2 có chuyến `TTX-ACCEPTANCE` với cước 42.000 đ; mở qua hàm migration thật, xác nhận **không mất snapshot, lịch sử**, tạo được bảng `banks` và cài mới v3 có đủ 3 bảng. Dọn DB thử trong finally, không yêu cầu GPS/mạng/quyền mới.
- Thêm `test/release_acceptance_test.dart`: luồng liên tính năng `TripController`→`MemoryCompletedTripStore`→`CompletedTrip.receiptSnapshot`→`ReceiptPdfData`→`VietQrTransferPayload`, kiểm tra 1,5 km, 360 giây waiting, 500 đ phí chờ, `roundVnd` đúng 500 vẫn **làm tròn xuống**, cộng BOT 5.000 đ sau cùng → tổng 35.000 đ; QR offline có CRC hợp lệ, không nhân đôi cuốc. Không tạo giao dịch thật.
- Tạo `docs/ACCEPTANCE_STEP23.md` với bảng tình trạng minh bạch và checklist trực tiếp trên Redmi: cài **đè** APK, lịch sử/snapshot, GPS Home và GPS chuyến khi ra nền, lọc nhiễu, pin, cước, PDF, ngân hàng VietQR, SOS, LED, tốc độ, Google Maps/Cloud và quyền Android. Không tự đánh dấu nghiệm thu thực địa; liên kết từ `README.md`.
- Thay đổi **3 tệp Dart** (mỗi tệp dưới 300 dòng), `README.md`, tài liệu nghiệm thu và `PROGRESS.md`. Không sửa `.github/`, `ci/`, debug keystore, package, 7 route, GPS filter, fare engine, chức năng SOS/LED hoặc VietQR payload.
- **Tại thời điểm commit:** CI của Bước 23 chưa được xác minh; chưa chạy thử nâng cấp với dữ liệu cá nhân trên Redmi hoặc số tiền giao dịch thật. Phải đọc Issue #1 cùng SHA commit mới, kiểm tra 4/4 trước khi sử dụng bản APK mới. Nếu CI lỗi thì ưu tiên sửa lỗi và không tiến thêm bước 24.
- **Việc cần kiểm tra trên điện thoại:** từng ô trong `docs/ACCEPTANCE_STEP23.md`, nhất là bảo toàn lịch sử, snapshot, GPS nền/đóng màn hình, bản đồ thật và số tiền/cước; không chia sẻ khóa API/OTP/vị trí riêng.
- **Bước tiếp theo:** 24 — xử lý phát hiện từ nghiệm thu hoặc khóa sổ mã debug khi có CI 4/4 và người dùng tiếp tục.


### Sửa lỗi CI #42 — dữ liệu thời gian chờ trong test nghiệm thu (20/11/2026)

- Đọc Issue #1 và CI #42 đúng commit `5f92205`: GitHub workflow **success** nhưng `flutter test` **lỗi 1 ca** (`test/release_acceptance_test.dart:40`), các mục `flutter analyze`, build APK debug arm64 và Android 13 đều đạt.
- Nguyên nhân: `TripController.tick()` giới hạn `delta` tối đa **30 giây mỗi lượt** để không tính thời gian ứng dụng đã đóng; test lại cộng 360 giây đồng hồ giả rồi chỉ gọi `tick()` **một lần**, khiến `waitingSeconds` thực tế chỉ 30, thay vì 360.
- Chỉ chỉnh **một file test Dart**: mô phỏng **12 lần x 30 giây**, mỗi lần gọi `tick()`, và kiểm tra `waitingSeconds == 360` trước `resume()`. Các kỳ vọng mốc 500 đ, làm tròn 30.500 → 30.000, BOT 5.000 → tổng 35.000 và QR/biên lai vẫn giữ nguyên.
- Cập nhật `PROGRESS.md`; **không thay** `TripController`, bộ lọc GPS, biểu phí, SQLite migration, VietQR/PDF, SOS/LED, app routes, quyền Android, signing hay workflow. **Bước 24 chưa bắt đầu**, chỉ tiếp tục sau khi CI của commit sửa lỗi đạt 4/4.


## Bước 24 — cổng bàn giao bản debug và chống hồi quy (20/11/2026)

- **Điều kiện:** Đã đọc Issue #1 và jobs của CI #43 commit `c473bb4`: **4/4 đạt**, gồm flutter analyze, flutter test, APK debug arm64 và Android 13 UI. Flutter phiên bản **3.50.1 stable**, SHA-1 debug vẫn `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`. Đã kiểm tra Release `debug-latest` build #43 tại thời điểm bắt đầu, target `c473bb4`.
- Đã đọc lại tệp gốc `MASTER PROMPT.md`, mục 1B/2/3 và lộ trình 10: lộ trình gốc kết thúc ở **mục 14 (Hoàn thiện)**. Các bước 15–24 là công việc mở rộng của dự án, không được mô tả là 24 mục gốc. Không triển khai chức năng mới cho taxi khi chưa có kết quả nghiệm thu Redmi.
- Thêm `test/release_guardrails_test.dart` (66 dòng, không dùng plugin native): kiểm tra package Android, đúng 7 `GoRoute`; `SharedMapView` dùng `GoogleMap`, JSON style/traffic SDK và không thêm `mapId`/`cloudMapId`; dependency `google_maps_flutter` ghim số phiên bản và không có một số package paid API; `GpsTracker` và Maps dùng mock trong CI, nhịp GPS chuyến **1s/0m** và Home **5s/10m**; cước tại mốc 500 đ và BOT cộng sau làm tròn. Test mã nguồn không xác nhận billing thật trên Google Cloud.
- Tạo `docs/DEBUG_RELEASE_GATE_STEP24.md`: biên bản release debug, cách so khớp SHA của Release/CI, khác biệt **CI đạt** so với **nghiệm thu Redmi** và **phát hành thương mại**, checklist thử nhanh khi xe dừng, rủi ro khóa ký debug trong repo public. Không tạo bản release chính thức hoặc tự ký phát hành.
- Cập nhật `docs/ACCEPTANCE_STEP23.md`: đánh dấu **CI Bước 23 đạt 4/4 từ #43**, giữ mọi checkbox kiểm thử Redmi thực tế chưa xác nhận. `README.md` liên kết hồ sơ bàn giao.
- Thay đổi **1 tệp Dart mới** và 4 tệp Markdown (`README.md`, `docs/DEBUG_RELEASE_GATE_STEP24.md`, `docs/ACCEPTANCE_STEP23.md`, `PROGRESS.md`); không thay logic hay dependencies, GPS, cước, SQLite, QR/PDF, SOS/LED, route, signing, CI workflow.
- **CI của commit Bước 24 chưa được xác minh tại lúc ghi tiến độ**; báo cáo Issue #1 của run mới phải được kiểm tra đủ 4/4. Nếu CI lỗi, sửa trước khi bước mới.
- **Cần thử trên điện thoại Redmi:** cài đè bản đã kiểm tra CI; đối chiếu lịch sử và snapshot, GPS Home ra nền/tắt, GPS chuyến foreground, thử cước/số tiền PDF và QR, SOS/LED, Google Maps thật/Cloud Billing. Không dùng app như thiết bị taxi đã kiểm định; chưa xác nhận nghiệm thu thực địa.
- **Bước tiếp theo: 25 — xử lý lỗi CI hoặc kết quả nghiệm thu thực tế có bằng chứng**, không tự bổ sung tính năng ngoài phạm vi Master Prompt.
