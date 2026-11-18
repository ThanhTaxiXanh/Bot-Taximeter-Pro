# BỘT TAXIMETER PRO — TIẾN ĐỘ

Cập nhật: 18/11/2026 (giờ Việt Nam). Repository: ThanhTaxiXanh/Bot-Taximeter-Pro, nhánh main.

## Đã làm

- **Bước 1:** Khởi tạo Flutter, Riverpod, GoRouter, 7 tuyến màn hình, cờ CI và 5 file CI/CD nguyên văn Phụ lục A.
- **Bản vá CI #1:** bỏ import Flutter Material không sử dụng trong integration_test/app_smoke_test.dart, commit 4bb69334. Chưa có báo cáo CI mới xác nhận bản vá.
- **Bước 2:** palette navy/cyan, ThemeData tối, Be Vietnam Pro qua google_fonts, nền gradient, viền và thẻ kính mờ BackdropFilter, nút gradient neon, cụm nút bản đồ, ô thống kê, bản đồ mini CustomPainter.
- Các widget dùng chung đã tạo: AppShell, GlassCard, NeonButton, MapControlButtons, StatCard, RoutePreviewPainter và RoutePreview.
- main.dart áp dụng AppTheme.dark. Giữ nguyên 7 tuyến màn hình và nhãn chữ phục vụ smoke test.
- Đồng bộ AppConfig.packageName và AppConfig.applicationId = vn.bottaximeter.bot_taximeter_pro theo package hiện tại người dùng đã chọn.
- Giữ nguyên README.md, 7 ảnh thiết kế, ci/debug.keystore và 4 file CI/script.

## Cây thư mục hiện tại

```text
.
├── .github/workflows/ci.yml
├── .gitignore
├── PROGRESS.md
├── README.md
├── analysis_options.yaml
├── ci/
│   ├── debug.keystore (CI tạo, không chỉnh sửa)
│   └── scripts/
│       ├── prepare_android.sh
│       ├── patch_android.py
│       └── make_report.py
├── docs/design/ (7 ảnh và README.md)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/
│   │   ├── app_config.dart
│   │   ├── router/app_router.dart
│   │   └── theme/app_colors.dart
│   ├── shared/
│   │   ├── app_shell.dart
│   │   ├── glass_widgets.dart
│   │   └── route_preview_painter.dart
│   └── main.dart
└── pubspec.yaml
```

`android/` chưa có trong repo, CI tự tạo bằng flutter create.

## Dependencies và phiên bản

| Package | Phiên bản |
|---|---|
| flutter_riverpod | 3.5.0 |
| go_router | 18.1.4 |
| google_fonts | 8.1.0 |
| flutter_lints (dev) | 6.0.0 |
| flutter_test (dev) | Flutter SDK |
| integration_test (dev) | Flutter SDK |

- Dart SDK: >=3.12.0 <4.0.0.
- Báo cáo CI #1 dùng Flutter 3.50.0 stable. Khuyến nghị ghim biến FLUTTER_VERSION = 3.50.0.

## Quyết định kỹ thuật

- Xây dựng UI mock trước, logic cước, GPS, OSM, SQLite, PDF, VietQR sẽ làm ở các bước riêng.
- Cờ kCI=true không dùng Google Fonts tải mạng: AppTheme chọn TextTheme hệ thống. Không có animation lặp vô hạn.
- Trên thiết bị thật, google_fonts được cache sau lần tải đầu. Nếu mở app lần đầu offline mà chưa có cache, cần thử fallback và cân nhắc đóng gói Be Vietnam Pro trong assets ở bước hoàn thiện.
- RoutePreviewPainter vẽ lộ trình giả từ điểm chuẩn hóa trong khung gradient. Không khởi tạo GoogleMap và không gọi Static Maps API.
- Các widget AppShell/GlassCard/NeonButton/MapControlButtons/StatCard được định nghĩa trong Bước 2; việc tích hợp đầy đủ vào Home ở Bước 3.
- Chỉ dùng ứng dụng cá nhân; mã mới ở Bước 2 không gọi mạng/GPS/Google Maps.
- Tên package hiện dùng trong Google Cloud Console: vn.bottaximeter.bot_taximeter_pro.

## Kết quả CI gần nhất

- Issue: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1
- **CI #1**, commit 00e9db5: Flutter 3.50.0, unit/widget test đạt, APK debug đạt, smoke test Android 13 đạt, flutter analyze có 1 warning unused import.
- Warning đã được sửa trong commit 4bb69334. Chưa có báo cáo đúng commit Bước 2 nên chưa thể xác nhận CI xanh.
- SHA-1 khóa debug: 8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4.

## Lỗi đã biết / rủi ro

- Chưa chạy Flutter trực tiếp ở phiên này, chờ báo cáo CI theo commit mới để kiểm chứng.
- Repo hiện công khai và lưu khóa ký debug cố định, ai có khóa đều có thể ký APK trùng chứng chỉ; nên chuyển repository về private.
- Google Maps thật chưa tích hợp (Bước 8), chưa thể xác nhận khóa Maps hoạt động.
- Be Vietnam Pro có thể cần tải lần đầu; offline-first hoàn chỉnh cần gói font trong assets hoặc kiểm chứng fallback.
- Các màn hình hiện vẫn là placeholder, mới có theme và component dùng chung.

## Cần thử trên điện thoại

- APK debug mới trên Redmi Note 12 Pro: khởi động, hiển thị tiếng Việt, font, điều hướng 7 màn và hộp thoại kết thúc.
- Khi tích hợp AppShell ở Bước 3, xem viền cyan, thẻ kính mờ và gradient trên màn thực tế.
- Sau Bước 8–9: GPS thật, tốc độ, độ chính xác, bản đồ, quyền vị trí, dịch vụ chạy nền và tối ưu pin MIUI.
- Kiểm tra Maps với package vn.bottaximeter.bot_taximeter_pro và SHA-1 trên CI.

## Việc tiếp theo

**Bước 3 — Màn 1 Home mock:** dùng AppShell và các shared widgets, nền bản đồ giả gradient + painter, các chip GPS/3D/Follow xe, tốc độ và biển số, cụm nút bản đồ, 4 nút chức năng, Bắt đầu/Lịch sử. Giữ nguyên các nhãn chữ smoke test.
