# BỘT TAXIMETER PRO — PROGRESS

Cập nhật: 18/11/2026 (giờ Việt Nam).
Repository: `ThanhTaxiXanh/Bot-Taximeter-Pro`; nhánh `main`.

## Đã làm

- **Bước 1:** Flutter `bot_taximeter_pro`, Riverpod, GoRouter 7 route; `kCI`; bộ GitHub Actions từ Master Prompt.
- **Bước 2:** Theme dark navy/cyan; `AppShell`, `GlassCard`, `NeonButton`, `MapControlButtons`, `StatCard`, `RoutePreviewPainter`; `google_fonts`.
- **Bước 3:** Màn Home mock có bản đồ tự vẽ, chip GPS/3D/Follow xe, tốc độ, biển giới hạn minh họa, 4 chức năng, Bắt đầu và Lịch sử.
- **Bước 4:** Màn Tìm kiếm và Lập tuyến với POI, 3 tuyến, ETA, quãng đường và giá mẫu; truyền điểm đi/đến qua `GoRouter.extra`.
- **Bước 5:** Màn Đang chạy chuyến với đồng hồ mỗi giây giả lập, Tạm dừng/Tiếp tục, tổng cước mẫu, phụ phí BOT, xác nhận Kết thúc, SOS chỉ hiển thị cảnh báo.
- **Bước 6:** Màn 5 `HistoryPage` theo ảnh `IMG_4492.png`. Có ba bộ lọc `Hôm nay`, `7 ngày`, `30 ngày`, lưới 2×2 doanh thu/số cuốc/quãng đường/giờ hoạt động; biểu đồ doanh thu bảy cột bằng `fl_chart` với ngày, giá trị trên cột và tổng 8.436.000 đ.
- Thêm sáu cuốc xe **dữ liệu mẫu**. Mặc định hiện ba cuốc hôm nay, nút `Xem tất cả` mở các cuốc thuộc kỳ đã chọn; mỗi cuốc hiển thị bản đồ thu nhỏ, thời gian, điểm đón/trả, thanh toán, cước và huy hiệu `Hoàn thành`.
- Cuốc nổi bật có `Xem chi tiết` (mở biên lai placeholder Màn 6, truyền snapshot mẫu) và `Xuất hóa đơn` (thông báo rõ chưa xuất file thật). Cuốc khác chạm để mở chi tiết.
- `HistoryPage` thay placeholder `_HistoryPage` trong `app_router.dart` mà **không đổi** route `/history`; giữ nhãn `Các cuốc xe gần đây` cho smoke test.
- Thêm `test/history_page_test.dart` kiểm thử bộ lọc, biểu đồ và điều hướng sang biên lai.
- Thêm dependency `fl_chart: 1.3.1`; không đổi những dependency đã ghim.
- Giữ nguyên 5 file CI/scripts, `ci/debug.keystore`, `integration_test/app_smoke_test.dart`, bảy ảnh thiết kế và các màn trước.

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
├── docs/design/ (7 ảnh và README.md)
├── integration_test/app_smoke_test.dart
├── lib/
│   ├── core/
│   │   ├── app_config.dart
│   │   ├── router/app_router.dart
│   │   └── theme/app_colors.dart
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
│   │   └── trip/presentation/trip_page.dart
│   ├── shared/
│   │   ├── app_shell.dart
│   │   ├── glass_widgets.dart
│   │   └── route_preview_painter.dart
│   └── main.dart
├── pubspec.yaml
└── test/
    ├── history_page_test.dart
    ├── home_page_test.dart
    ├── search_route_page_test.dart
    └── trip_page_test.dart
```

`android/` chưa có trong git; CI tự tạo khi build.

## Dependencies và phiên bản

| Package | Phiên bản |
|---|---|
| `flutter_riverpod` | `3.5.0` |
| `go_router` | `18.1.4` |
| `google_fonts` | `8.1.0` |
| `fl_chart` | `1.3.1` (thêm Bước 6) |
| `flutter_lints` (dev) | `6.0.0` |
| `flutter_test` (dev) | Flutter SDK |
| `integration_test` (dev) | Flutter SDK |

Dart SDK `>=3.12.0 <4.0.0`. CI #9 sử dụng Flutter **3.50.0** stable. Có thể ghim `FLUTTER_VERSION=3.50.0`.

## Quyết định kỹ thuật

- Bước 6 là **giao diện với dữ liệu giả**, không truy cập doanh thu thật, không lưu lịch sử, không gọi SQLite/GPS/Google Maps hoặc API bên ngoài.
- Dữ liệu ngày 20–26/01 và các cuốc TTX-250126-* được giữ theo **ảnh thiết kế** (không phải ngày thực hiện hiện tại). Giao diện có nhãn `DỮ LIỆU MẪU` để tránh hiểu nhầm.
- Biểu đồ `fl_chart` hiển thị bảy cột tĩnh; toàn màn có ba bộ lọc thay đổi thống kê tổng và danh sách cuốc mẫu, biểu đồ vẫn mô tả 7 ngày thiết kế.
- Lọc cuốc bằng `dayOffset` giả; không tự nhận biết `DateTime.now()`. Có 3 cuốc Hôm nay, 5 cuốc trong 7 ngày và 6 cuốc trong 30 ngày; nút `Xem tất cả` điều khiển số cuốc đang thấy.
- `HistoryRevenueChart` không hoạt ảnh kéo dài để tránh ảnh hưởng smoke test; `BarChartRodLabel` hiển thị số tiền trên cột.
- Thẻ cuốc dùng lại `GlassCard` và `RoutePreview`, không dùng `GoogleMap` cho mỗi cuốc. Điều này phù hợp định hướng chi phí API thấp.
- Nút `Xem chi tiết` truyền thông tin cuốc qua `GoRouter.extra` vào placeholder biên lai có sẵn. `Xuất hóa đơn` không tạo file và có thông báo về tính năng chưa triển khai.
- Chưa có kết quả phân tích/test của commit Bước 6. Số liệu mặc định 1.284.000 đ, 14 cuốc, 83,4 km, 6 giờ 42 phút chỉ là minh họa.
- Package Android giữ nguyên `vn.bottaximeter.bot_taximeter_pro`.

## Kết quả CI gần nhất

- Báo cáo tự cập nhật: https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1
- **CI #9**, commit Bước 5 `f0cb7cd`: `flutter analyze` ✅, `flutter test` ✅, build APK debug ✅, smoke test Android 13 ✅.
- Phiên bản Flutter: 3.50.0 stable. SHA-1 debug: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`.
- **Chưa có CI của commit Bước 6**. Không kết luận Bước 6 đã đạt cho tới khi GitHub Actions chạy xong.

## Lỗi đã biết / rủi ro

- Môi trường tác giả không có Flutter SDK để chạy `flutter analyze`/`flutter test` tại chỗ; CI sẽ xác minh code/chart mới.
- Các cuốc mẫu, số tiền, giờ/đường và biến động thống kê không phải dữ liệu giao dịch, không dùng làm báo cáo tài chính thực.
- Màn Biên lai chi tiết và chức năng PDF/in/chia sẻ sẽ triển khai trong Bước 7; nút Xuất hóa đơn hiện chỉ thông báo.
- Repo hiện công khai và có khóa debug cố định `ci/debug.keystore`: người khác có thể ký APK bằng cùng chứng chỉ. Khuyến nghị chuyển repo private.
- Font Be Vietnam Pro có thể cần tải lần đầu; GPS/bản đồ/thu cước thật và SOS đều chưa tích hợp.

## Cần thử trên điện thoại

- Redmi Note 12 Pro: mở Lịch sử hoặc Doanh thu, kiểm tra giao diện trên màn hình thật, không tràn chữ trong thẻ 2×2 và biểu đồ 7 cột.
- Thử Hôm nay/7 ngày/30 ngày, `Xem tất cả` và `Thu gọn`; xác nhận số liệu mẫu đổi đúng.
- Chạm `Xem chi tiết` và thẻ cuốc khác để kiểm tra biên lai hiển thị tiền theo cuốc mẫu; chạm `Xuất hóa đơn` để kiểm tra cảnh báo chưa có chức năng thật.
- Kiểm tra cuộn tới thanh thông tin cuối cùng, tốc độ cuộn mượt và giao diện trên MIUI.
- Kiểm tra các luồng cũ: Home → Tìm kiếm/Tuyến đường/Đang chạy/Doanh thu/Cài đặt và kết thúc chuyến.

## Việc tiếp theo

**Bước tiếp theo: 7 — Màn 6 Chi tiết chuyến đi/biên lai, thanh toán tiền mặt/chuyển khoản, VietQR mẫu, In biên lai/Chia sẻ/Xuất PDF.** Cần giữ nhãn smoke test.
