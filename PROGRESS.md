# BỘT TAXIMETER PRO — TIẾN ĐỘ

Cập nhật: 18/11/2026 (giờ Việt Nam). Repository: `ThanhTaxiXanh/Bot-Taximeter-Pro`, nhánh `main`.

## Đã làm

- **Bước 1 — Hạ tầng**: thêm `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `lib/main.dart`, `lib/core/app_config.dart`, `lib/core/router/app_router.dart`.
- Tích hợp Riverpod `ProviderScope`; GoRouter có đúng 7 tuyến: `/`, `/search`, `/route`, `/trip`, `/history`, `/receipt`, `/settings`.
- Tạo giao diện khung đơn giản, có nhãn phục vụ smoke test: Home và điều hướng, Tìm kiếm, Tuyến đường, Đang chạy chuyến (tạm dừng/tiếp tục/xác nhận kết thúc), Lịch sử, Biên lai, Cài đặt. Đây là placeholder, **chưa phải giao diện 7 ảnh thiết kế**.
- `kCI` được khai báo là `const bool kCI = bool.fromEnvironment('CI')`; giai đoạn này không có gọi GPS, mạng hay Google Maps.
- Chép **nguyên văn** 5 file từ Phụ lục A: `.github/workflows/ci.yml`, `ci/scripts/prepare_android.sh`, `ci/scripts/patch_android.py`, `ci/scripts/make_report.py`, `integration_test/app_smoke_test.dart`.
- Giữ nguyên `README.md` và 7 ảnh trong `docs/design/`. Không tạo/chỉnh sửa `ci/debug.keystore`.

## Cây thư mục hiện tại

```text
.
├── .github/workflows/ci.yml
├── .gitignore
├── PROGRESS.md
├── README.md (giữ nguyên)
├── analysis_options.yaml
├── ci/scripts/
│   ├── make_report.py
│   ├── patch_android.py
│   └── prepare_android.sh
├── docs/design/ (7 ảnh thiết kế và README.md giữ nguyên)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/
│   │   ├── app_config.dart
│   │   └── router/app_router.dart
│   └── main.dart
└── pubspec.yaml
```

`android/` chưa có trong repo; workflow sẽ tạo ở CI bằng `flutter create`.

## Dependencies đã ghim

| Package | Phiên bản |
|---|---|
| `flutter_riverpod` | `3.5.0` |
| `go_router` | `18.1.4` |
| `flutter_lints` (dev) | `6.0.0` |
| `flutter_test` (dev) | Flutter SDK |
| `integration_test` (dev) | Flutter SDK |

SDK Dart yêu cầu `>=3.12.0 <4.0.0`. Flutter của CI: **chưa có báo cáo CI nên chưa biết bản chính xác**; sau build đầu tiên, ghi lại số từ báo cáo và thiết lập biến `FLUTTER_VERSION`.

## Quyết định kỹ thuật

- Đầu tiên chỉ dùng Flutter UI cơ bản, Riverpod, GoRouter. Các chức năng tính cước, bản đồ, GPS, lưu SQLite, VietQR sẽ thêm theo đúng thứ tự lộ trình.
- Tạo GoRouter mới khi app khởi tạo để các bài kiểm thử không dùng lại lịch sử điều hướng từ bài trước.
- `AppConfig.appNameLine1` và `appNameLine2` là nguồn duy nhất cho tên ứng dụng trong Dart.
- Mã Flutter do AI mới viết; 5 file CI lấy nguyên văn từ Master Prompt.
- Chưa có mã tính cước/logic thuần; unit test sẽ được thêm đồng thời với các module liên quan.

## Kết quả CI gần nhất

- **Chưa có kết quả** từ GitHub Actions cho commit Bước 1. Không thể xác nhận `flutter analyze`, `flutter test`, smoke test hay APK đã đạt.
- File smoke test của Phụ lục A giữ nguyên theo chỉ định; giao diện chi tiết sẽ được triển khai lần lượt ở các bước sau.

## Lỗi đã biết / điểm cần đối chiếu

- **Khác biệt application ID**: lệnh CI `flutter create --org vn.bottaximeter --project-name bot_taximeter_pro .` dự kiến sinh Android `applicationId` là `vn.bottaximeter.bot_taximeter_pro`, trong khi Phụ lục B yêu cầu giới hạn Google Maps key với `vn.bottaximeter.pro`. `AppConfig.packageName` không thay đổi `applicationId` thật. Giữ nguyên bộ CI theo yêu cầu; cần thống nhất package/điều chỉnh Android trước khi bật khóa giới hạn Maps ở Bước 8.
- Repo GitHub hiện tại là **công khai**. Sau khi CI đẩy `ci/debug.keystore`, người khác có thể lấy khóa debug, ký APK có cùng chữ ký. Cân nhắc chuyển repo sang riêng tư.
- Giao diện hiện tại chỉ là khung; dữ liệu đồng hồ, bản đồ, các màn 2–7 vẫn là placeholder.

## Cần thử trên điện thoại

- APK khởi chạy trên Redmi Note 12 Pro; chuyển giữa 7 màn và xác nhận kết thúc chuyến.
- Bước sau: bản đồ Google Maps thật, quyền vị trí, định vị GPS, lọc nhiễu, tốc độ hiển thị, thông báo dịch vụ nền, tối ưu pin MIUI.
- Kiểm tra SHA-1 khóa debug và package thực tế trước khi giới hạn Maps API key.

## Việc tiếp theo

**Bước 2 — Theme + token màu + shared widgets**: `AppShell`, `GlassCard`, `NeonButton`, `MapControlButtons`, `StatCard`, `RoutePreviewPainter`. Giữ tương thích nhãn smoke test và không sửa bộ CI khi không có lỗi liên quan.