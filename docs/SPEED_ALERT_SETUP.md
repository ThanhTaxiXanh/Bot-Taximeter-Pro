# BỘT TAXIMETER PRO — Nâng cấp cảnh báo tốc độ (Bước 12, phần cơ sở)

## Giới hạn phạm vi

Master Prompt gốc chưa có trong repository. Đây là phần nâng cấp có thể kiểm chứng an toàn sau Bước 11, **không thay thế việc đối chiếu đầy đủ yêu cầu Bước 12** trong Master Prompt.

Bộ cảnh báo tốc độ **không xác định giới hạn pháp lý** từ bản đồ Google, dữ liệu OpenStreetMap hoặc các CSV biển báo chưa được xác minh. Không sử dụng dữ liệu Mapillary/no-entry hay tốc độ mẫu để khẳng định biển báo thật. Mặc định cảnh báo **TẮT**.

## Sử dụng trên điện thoại

1. Vào **Cài đặt → Cảnh báo tốc độ cá nhân**.
2. Chủ động bật và chọn **ngưỡng tự đặt** (40, 50, 60, 70, 80, 90, 100, 120 km/h), bấm **Lưu cảnh báo tốc độ**.
3. Khi đã được cấp quyền GPS, banner cảnh báo xuất hiện ở Home và Đang chạy chuyến. Không có vị trí GPS đủ tin cậy thì báo “GPS chưa đủ tin cậy”, không đoán tốc độ.
4. Ứng dụng chỉ bật trạng thái cảnh báo sau **3 điểm GPS liên tiếp** có tốc độ vượt ngưỡng cá nhân hơn 5 km/h; cần **2 điểm** xuống dưới ngưỡng +1 km/h mới xóa trạng thái vượt.
5. Không nối chuỗi vượt nếu GPS ngắt hơn 4 giây, không dùng fix cũ trên 5 giây, độ chính xác >15 m, tọa độ giả lập hoặc tốc độ bất thường >200 km/h; chống lặp sự kiện cảnh báo tối thiểu 30 giây.

**Cảnh báo:** Ngưỡng tự đặt không phản ánh tốc độ tối đa hợp pháp của đoạn đường. Tài xế phải quan sát biển báo thật và tuân thủ pháp luật giao thông. Không thao tác trên điện thoại khi đang lái xe.

## Bảo vệ dữ liệu và chi phí

- Không gọi thêm dịch vụ mạng/API; chỉ dùng GPS lọc sẵn từ `GpsTracker`.
- Lưu hai giá trị cài đặt trong SharedPreferences trên thiết bị. Không thu thập lịch sử vị trí mới hoặc gửi thông tin vị trí cho bên thứ ba.
- Không thay đổi Fare Engine, SQLite, khôi phục chuyến, tính cước, routing OSRM hoặc bộ CI.

## Kiểm thử

Các bài test mới `speed_alert_engine_test.dart` và `speed_alert_widgets_test.dart` dùng GPS giả lập bằng dữ liệu đầu vào thuần Dart và SharedPreferences mock. Smoke test Android 13 hiện có vẫn dùng `CI=true` nên không yêu cầu vị trí thật.

Cần thử thực địa bằng GPS thật trên Redmi Note 12 Pro khi xe **đỗ** hoặc có người phụ trách kiểm thử, không kiểm tra bằng cách chạy quá tốc độ. Có thể thử ngưỡng cảnh báo thấp trong khu vực thử nghiệm an toàn để xem UI, không dùng để xác định giới hạn hợp pháp.
