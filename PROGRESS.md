# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 18/11/2026 (giờ Việt Nam). Repository `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

## Đã làm

- **Bước 1:** Khởi tạo Flutter/Riverpod/GoRouter, Android CI tạo tự động, bộ CI trong `.github/` và `ci/`.
- **Bước 2:** Theme navy/cyan, thẻ kính mờ, AppShell và các widget dùng chung.
- **Bước 3:** Home mock với trạng thái GPS/tốc độ, bản đồ tự vẽ và các nút chính.
- **Bước 4:** Tìm kiếm/lập tuyến mẫu; chọn POI và phương án, không gọi dịch vụ định tuyến.
- **Bước 5:** Chuyến đi mô phỏng, đồng hồ và cước mẫu, tạm dừng, phụ phí BOT, hộp thoại kết thúc/SOS.
- **Bước 6:** Lịch sử/doanh thu giả, `fl_chart`, lọc 3 kỳ, sáu cuốc mẫu.
- **Bước 7:** Biên lai, QR DEMO không thanh toán, Cài đặt lưu bằng `shared_preferences`.
- **Sửa lỗi CI #11 trước Bước 8:** báo cáo 11 cho commit `c9d0a95` có 2 warning import trong Settings, 2 hàng `Row` tràn ngang trong Receipt (9,5 và 18 px), và `SwitchListTile` bị `DecoratedBox` che `Material` gây exception (widget test và smoke Android). Sửa ở `settings_page.dart`, `settings_widgets.dart`, `receipt_page.dart` trong commit `9b674f4`, chưa có báo cáo CI xác nhận riêng.
- **Bước 8:** thêm `SharedMapView` vào `lib/shared/shared_map_view.dart` cho Home, Lập tuyến và Đang chạy chuyến. Khi chạy APK thật trên Android (không có cờ CI), widget hiển thị `GoogleMap` với style JSON dark/light, buildings 3D (nếu Google có dữ liệu), traffic layer, mũi tên xe tự vẽ PNG bằng Canvas, và polyline của ba tuyến mẫu.
- `SharedMapView` có `recenter()`, `onCameraMoveStarted` để ngừng Follow khi người dùng kéo, `onCameraIdle` để phân biệt camera điều khiển bằng mã. Thay đổi 2D/3D điều chỉnh camera tilt; tải góc nghiêng từ giá trị `map_tilt` của `shared_preferences` (mặc định 60°). Camera zoom/bearing có tham số chuẩn bị cho bước GPS.
- **Điều kiện test:** `kCI=true` hoặc môi trường `flutter test` (`FLUTTER_TEST=true`) chỉ vẽ `HomeMockMap`/`MockRouteMap` bằng Canvas, không khởi tạo GoogleMap, không xin quyền GPS, không gọi Maps API. Thêm `test/shared_map_view_test.dart` xác minh fallback và recenter không truy cập SDK.
- **Vị trí mẫu:** `LatLng(21.2741, 106.1946)` là tọa độ giả lập cố định gần Bắc Giang theo bối cảnh ảnh, KHÔNG PHẢI vị trí tài xế. Ba polyline cũng là dữ liệu mẫu, không phải đường có thể điều hướng. Trên bản đồ thật hiện chú thích `VỊ TRÍ MẪU · GPS CHƯA KẾT NỐI`. GPS thật và lọc nhiễu thuộc Bước 9.
- Giữ nguyên đường dẫn và nhãn smoke test, cài đặt 7 màn, test cũ, 5 file CI/scripts, `ci/debug.keystore`, bảy ảnh trong `docs/design/`. Không tạo GoogleMap trong thẻ thumbnail/lịch sử/biên lai.

## Cây thư mục hiện tại

```text
.
├── .github/workflows/ci.yml
├── .gitignore
├── PROGRESS.md
├── README.md
├── analysis_options.yaml
├── assets/
│   ├── images/logo.png
│   └── map_styles/{dark.json,light.json}
├── ci/
│   ├── debug.keystore
│   └── scripts/{prepare_android.sh,patch_android.py,make_report.py}
├── docs/
│   ├── GOOGLE_MAPS_SETUP.md
│   └── design/ (7 ảnh và README.md)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/{app_config.dart,router/app_router.dart,theme/app_colors.dart}
│   ├── features/
│   │   ├── history/presentation/{history_mock_data.dart,history_page.dart,history_widgets.dart}
│   │   ├── map_tracking/presentation/
│   │   │   ├── home_map_mock.dart,home_page.dart,home_widgets.dart
│   │   │   ├── mock_travel_data.dart,route_page.dart,search_page.dart
│   │   ├── receipt/presentation/{receipt_page.dart,receipt_widgets.dart}
│   │   ├── settings/presentation/{settings_page.dart,settings_widgets.dart}
│   │   └── trip/presentation/trip_page.dart
│   ├── shared/
│   │   ├── app_shell.dart,glass_widgets.dart,route_preview_painter.dart
│   │   └── shared_map_view.dart
│   └── main.dart
├── pubspec.yaml
└── test/{history_page_test.dart,home_page_test.dart,search_route_page_test.dart,
          shared_map_view_test.dart,step7_pages_test.dart,trip_page_test.dart}
```

`android/` do CI tự tạo bằng `flutter create` và vá qua `ci/scripts/patch_android.py`.

## Dependencies và phiên bản

| Package | Phiên bản |
|---|---|
| `flutter_riverpod` | 3.5.0 |
| `go_router` | 18.1.4 |
| `google_fonts` | 8.1.0 |
| `fl_chart` | 1.3.1 |
| `qr_flutter` | 4.1.0 |
| `shared_preferences` | 2.5.6 |
| **`google_maps_flutter`** | **2.19.0 (Bước 8)** |
| `flutter_lints` (dev) | 6.0.0 |
| `flutter_test`, `integration_test` (dev) | Flutter SDK |

Dart SDK `>=3.12.0 <4.0.0`. CI #11 dùng **Flutter 3.50.0 stable**. Có thể ghim biến `FLUTTER_VERSION=3.50.0`.

## Quyết định kỹ thuật

- `google_maps_flutter 2.19.0` có tham số `style`, `trafficEnabled`, `buildingsEnabled`, `onCameraMoveStarted` và Android minSdk 24; `ci/scripts/patch_android.py` đã đặt minSdk 24 và tự nhúng Maps API key từ Secret `MAPS_API_KEY` vào `AndroidManifest.xml`.
- API key **không nằm trong git**. Khi bản đồ trống trên điện thoại, kiểm tra `MAPS_API_KEY`, Maps SDK for Android, billing, package Android + SHA-1. Xem `docs/GOOGLE_MAPS_SETUP.md`.
- Bật Google Maps thật chỉ trong ứng dụng Android bình thường. CI và unit test dùng Canvas; không phát sinh yêu cầu bản đồ hay GPS trong test.
- Ba màn hiện đều có một *loại widget* `SharedMapView`, mỗi màn giữ controller riêng theo vòng đời widget. Điều khiển lớp giao thông dùng trực tiếp `trafficEnabled` của Maps SDK, không dùng API traffic riêng.
- Tối ưu chi phí: ảnh tuyến thu nhỏ trong Lịch sử/biên lai/Cài đặt dùng CustomPainter, không tạo GoogleMap thứ hai hay gọi Static Maps.
- Tên đường, trạng thái GPS, tốc độ, ETA, khoảng cách, chuyến và cước vẫn là dữ liệu mô phỏng; không được dùng để dẫn đường hoặc thu tiền thực.
- `SharedMapView` đọc góc nghiêng từ SharedPreferences. Các cấu hình 2D/3D, giao thông, tối/sáng trên Home/Route/Trip hiện do trạng thái từng màn; đồng bộ toàn diện với các giá trị trong Settings cần rà lại ở Bước 14.
- Google Maps 3D phụ thuộc hỗ trợ 3D buildings ở khu vực; tùy chọn 3D không bảo đảm có mô hình 3D mọi nơi.
- Dữ liệu tuyến thuộc Step 8 chỉ là polyline mẫu. Tìm kiếm Nominatim/OSRM và chỉ dẫn rẽ thật sẽ làm ở Bước 11. Không định tuyến tự động bằng Google.

## Kết quả CI gần nhất

- Báo cáo Issue: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1
- **CI #11**, commit `c9d0a95`: build APK debug ✅; flutter analyze ❌ (2 unused import); flutter test ❌ (4 bài do tràn Row Receipt/Material ListTile); smoke Android 13 ❌ (Màn Cài đặt).
- Đã sửa nhóm lỗi CI #11 trong commit `9b674f4`. **Chưa có báo cáo CI đúng commit Bước 8**, không khẳng định build/test mới đạt.
- SHA-1 debug: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.

## Lỗi đã biết / rủi ro

- Môi trường hiện tại không có Flutter/Dart SDK cục bộ. Cần đợi GitHub Actions xác nhận pub get, analyzer, test và build bản đồ Native cho commit Bước 8.
- Bản đồ Google thật phụ thuộc key hợp lệ, mạng và Google Play Services; không thể xác nhận bản đồ thực tế chỉ bằng emulator CI dùng `kCI`.
- Tọa độ marker và tuyến hiện chỉ minh họa; không có GPS thật, không có dẫn đường thực tế, **không dùng khi lái xe**.
- Repo public lưu debug keystore cố định (không an toàn cho phát hành công khai). Khuyến nghị để private.
- Có chi phí Google Maps SDK map loads trên thiết bị thật; nên đặt Budget và quota, không tạo bản đồ liên tục trong thumbnail.
- Các lựa chọn trên Settings về camera/bản đồ chưa liên kết hoàn chỉnh tới các màn; thiết bị cần thử và rà soát sau khi chức năng GPS được thêm.

## Cần thử trên điện thoại

- Cài APK debug mới trên Redmi Note 12 Pro: thấy tile Google Maps thật hay màn trắng, màu map sáng/tối, nhà 3D nếu khu vực hỗ trợ.
- Chuyển 2D/3D, bật/tắt Traffic, kéo bản đồ để kiểm tra Follow tắt, chạm định vị để trở lại tọa độ xe mẫu.
- Kiểm tra mũi tên xe xanh tự vẽ, ba tuyến mẫu, chuyển tuyến trong Màn Lập tuyến.
- **Vị trí xe hiện là mẫu cố định**: KHÔNG dùng để tìm đường/định vị trước Bước 9.
- Đảm bảo quyền Maps API chỉ dành Android package `vn.bottaximeter.bot_taximeter_pro` và SHA-1 debug đúng CI. Không dán API key vào chat hay repo.
- Thử hồi quy Màn Biên lai & Cài đặt sau lỗi CI #11: không tràn chữ và Switch không gây exception.
- Kiểm tra MIUI/Google Play Services, tốc độ render/độ ổn định và hạn mức Google Maps billing.

## Việc tiếp theo

**Bước tiếp theo: 9 — GPS thật, Haversine, lọc nhiễu và dịch vụ vị trí nền, reverse geocoding Nominatim có cache/giới hạn.**
