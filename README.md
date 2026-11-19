# BỘT TAXIMETER PRO

Ứng dụng Flutter Android **hỗ trợ tài xế taxi cá nhân**, có đồng hồ cước GPS **tham khảo**. Đây **không phải đồng hồ taxi được kiểm định**, không xác nhận giao dịch đã thu tiền, không thay thế việc tuân thủ biển báo giao thông.

## Sử dụng trên điện thoại Android

1. Mở [Actions](https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions), chọn lượt CI mới nhất và mở [Issue #1 — báo cáo CI](https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1). **Chỉ xem là đạt khi Issue #1 xác nhận cả 4 mục**: `flutter analyze`, `flutter test`, APK, integration Android 13. Lượt workflow ghi `success` vẫn có thể chứa test lỗi.
2. Sau khi CI đạt, mở [Release debug-latest](https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/releases/tag/debug-latest) để tải APK `BOT-TaxiMeterPro-debug.apk` về điện thoại. Khi cập nhật, **cài đè, không xóa ứng dụng/dữ liệu** để giữ lịch sử chuyến.
3. Cho phép **Vị trí chính xác khi sử dụng**. Chỉ bật GPS khi muốn dùng. Khi bắt đầu chuyến, ứng dụng có thể yêu cầu quyền thông báo và chạy foreground service. Xem [Hướng dẫn GPS](docs/GPS_SETUP.md).
4. Cài đặt biểu phí, thông tin VietQR, ngân hàng/BIN, máy chủ tìm địa chỉ/định tuyến tùy chọn và câu chào LED trong **Cài đặt**. Câu chào LED là bản xem trước, phải nhấn **Lưu cài đặt** mới lưu.
5. Trên Redmi/Xiaomi, nếu GPS bị hệ thống dừng giữa chuyến, cân nhắc **Pin → Không hạn chế**, bật thông báo và tự khởi động theo hướng dẫn. **Chỉ thao tác điện thoại khi xe đỗ an toàn**.

## Chức năng và giới hạn

| Chức năng | Tình trạng |
|---|---|
| GPS, theo dõi chuyến, lọc Haversine và khôi phục snapshot | Có; quãng đường/cước tham khảo |
| Biểu phí 4 bậc, phí chờ, BOT, tự lưu chuyến | Có; test thuần Dart, không phải đồng hồ kiểm định |
| Lịch sử và thống kê doanh thu | Từ những cuốc đã lưu trong SQLite |
| Tìm địa chỉ/định tuyến | Có khi tự cấu hình máy chủ HTTPS được phép; mặc định không gửi tọa độ tới máy chủ công cộng |
| Maps 2D/3D/traffic | Google Maps SDK for Android; không dùng Map ID, không gọi Places/Routes/Geocoding trả phí |
| VietQR | Payload offline, chọn ngân hàng qua cache/seed; chỉ yêu cầu chuyển khoản |
| PDF biên lai | Chỉ khi chuyến đã lưu; cần kiểm tra font tiếng Việt trên máy |
| SOS | Luôn yêu cầu xác nhận; mở trình gọi/chia sẻ, không tự gọi |
| LED chào khách | Màn hình chữ lớn mở từ Cài đặt |
| GPS tiết kiệm pin (Bước 22) | Home 5 giây/10 m; chuyến giữ 1 giây/0 m; GPS Home dừng khi app ra nền |

## Kiểm soát chi phí Google Maps và bảo mật

**Kiểm tra lại giá tại thời điểm sử dụng:** Theo bảng giá chính thức của Google, SKU **Maps SDK** trên Android có mức miễn phí không giới hạn; **Map ID** và các API trả phí khác có thể phát sinh chi phí. Đây là mô tả giá hiện hành, **không bảo đảm hóa đơn luôn bằng 0** hoặc giá không thay đổi.

- [Hướng dẫn tạo/giới hạn API key, SHA-1, Budget và quota](docs/GOOGLE_MAPS_SETUP.md).
- [Kiểm toán pin và chi phí Google Maps — Bước 22](docs/BATTERY_MAPS_AUDIT_STEP22.md).
- [Báo cáo tiến độ và kết quả CI](PROGRESS.md).
- Chỉ bật **Maps SDK for Android** trong dự án Cloud dành cho app này; giới hạn key theo **Android package + SHA-1**.
- Application ID thực tế của repo: `vn.bottaximeter.bot_taximeter_pro`; xem SHA-1 **đúng bản APK** ở Issue #1/CI, không dùng package cũ `vn.bottaximeter.pro` từ tài liệu khởi tạo.
- Khóa `MAPS_API_KEY` nằm trong **GitHub Secrets**, không ghi thẳng vào Dart/README; debug keystore không phù hợp để ký bản phát hành chính thức. Nên dùng repo private và khóa ký release riêng khi phát hành.
- Tạo **Cloud Billing Budget + Alerts** và kiểm tra usage/quota định kỳ; **budget alerts chỉ cảnh báo, không tự chặn thanh toán**.
- Không bật Map ID, Street View, Places, Directions/Routes, Static Maps, Geocoding hay Map Tiles API trong ứng dụng này.

## Nghiệm thu bản debug trên điện thoại

Xem [**Checklist nghiệm thu Bước 23**](docs/ACCEPTANCE_STEP23.md) trước khi dùng thực địa. CI chỉ xác minh mã/app trên máy ảo; GPS thật, hao pin, bản đồ với key Google, dữ liệu sau cài đè và VietQR cần được kiểm tra trên thiết bị Redmi. **Không gỡ ứng dụng để nâng cấp nếu muốn giữ lịch sử chuyến.**

## Công nghệ, kiểm thử, cấu trúc

- Flutter (phiên bản ghi trong CI), Riverpod, GoRouter **7 tuyến**, `geolocator`, `google_maps_flutter`, `sqflite`, `pdf`, `printing`, `shared_preferences`.
- Trong `CI=true`/widget test, bản đồ dùng **Canvas** thay vì native GoogleMap; GPS và network thật không tự chạy.
- Mã nguồn `lib/`; unit/widget `test/`; Android integration `integration_test/`; tài liệu `docs/`; tiến độ `PROGRESS.md`.
- Không chỉnh `.github/`, `ci/` hoặc debug signing thủ công khi chưa có lỗi CI bắt buộc. **Bước 22 không thay đổi các tệp CI**.

## Tài liệu bổ sung

[GPS trên Redmi](docs/GPS_SETUP.md) · [Bản đồ Google](docs/GOOGLE_MAPS_SETUP.md) · [Máy chủ OSRM/Nominatim](docs/ROUTING_SETUP.md) · [VietQR](docs/VIETQR_TRANSFER.md) · [Ngân hàng VietQR](docs/VIETQR_BANKS_STEP20.md) · [Màn LED](docs/LED_GREETING_STEP21.md)

**Nghiệm thu:** CI là kiểm thử tự động; còn phải cài đè và thử trên điện thoại Android thật, đặc biệt GPS nền, nâng cấp SQLite, in PDF và Maps với API key thật.
