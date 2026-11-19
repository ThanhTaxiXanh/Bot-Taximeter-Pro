# BỘT TAXIMETER PRO — Bước 13: Lịch sử và thống kê cước GPS

## Thay đổi

- Chỉ khi tài xế **xác nhận Kết thúc**, TripController ghi một hàng vào `completed_trips`, theo ID từ thời điểm bắt đầu chuyến. Trùng ID không ghi thêm, tránh nhân đôi doanh thu.
- Sau khi ghi thành công, mới xóa snapshot `trip_snapshots`. Nếu lưu lịch sử lỗi, giữ snapshot và cho tài xế thử lại, không dẫn sang biên lai.
- SQLite nâng từ phiên bản 1 lên 2. `onUpgrade` chỉ tạo bảng `completed_trips` và index; **không xóa bảng snapshot cũ**. Bước này vẫn cần thử nâng cấp trực tiếp từ APK cũ trên Redmi Note 12 Pro.
- `completed_trips` lưu ID, mốc bắt đầu/kết thúc, tổng cước GPS tham khảo, mét GPS đã lọc, giây chuyến, giây chờ, phí chờ và BOT. Không thu thập vị trí từng giây, địa chỉ khách hoặc thông tin thanh toán mới.
- Màn Lịch sử/Doanh thu dùng các chuyến đã ghi, tự lọc theo ngày địa phương (hôm nay, 7 ngày, 30 ngày); biểu đồ 7 ngày cũng đọc dữ liệu thật.
- Biên lai từ lịch sử được dựng từ số liệu chuyến đã lưu; các trường chưa thu thập như điểm đón/trả được ghi **Chưa ghi nhận**, không lấy địa chỉ mẫu.
- Tổng cước tham khảo **không phải doanh thu đã nhận**. Không xác nhận thanh toán, không tạo hóa đơn thuế, VietQR thật hoặc PDF.

## Ranh giới kiểm thử

- Unit/widget test dùng `MemoryCompletedTripStore` và `MemoryTripStore`.
- `integration_test/completed_history_test.dart` chủ động kiểm tra SQLite native trên Android 13 trong CI, không cần Maps key hoặc GPS.
- Giữ nguyên `integration_test/app_smoke_test.dart` và cấu hình workflow; Android package vẫn là `vn.bottaximeter.bot_taximeter_pro`.
- Chưa có xác nhận trên Redmi thực tế. Cần thử nâng cấp từ APK #24 khi đang có snapshot, chọn Khôi phục, kết thúc, đóng/mở lại rồi kiểm tra danh sách và doanh thu.
- Cần thử mất bộ nhớ/SQLite lỗi. **Không gỡ ứng dụng hoặc xóa dữ liệu** trước khi thử nâng cấp vì sẽ làm mất lịch sử/snapshot.

## Hướng dẫn kiểm tra Redmi Note 12 Pro

1. Cài APK mới lên APK hiện tại (không gỡ), mở Home và các mục cũ.
2. Bắt đầu cuốc thử khi đỗ xe, kiểm tra giá mở cửa 30.000 đ; cộng BOT thử rồi kết thúc, xác nhận.
3. Vào **Lịch sử** và **Doanh thu**, xác nhận đúng số cuốc và số tiền; chọn 7/30 ngày.
4. Chạm **Xem chi tiết**, xác nhận biên lai khớp cước, BOT, thời gian; địa chỉ không biết phải để **Chưa ghi nhận**.
5. Khởi động lại app, kiểm tra chuyến vẫn còn và không tạo thêm hàng trùng. Với snapshot cũ (APK trước), thử khôi phục và hoàn tất.
6. Không dùng các tổng cước này để xác nhận khách đã thanh toán hoặc để xuất hóa đơn thuế.

Cần đối chiếu nguyên văn Master Prompt để xác định các yêu cầu Bước 13 khác. Không tự triển khai thanh toán thật khi chưa có thông số nghiệp vụ và xác thực ngân hàng.
