# Thiết lập Google Maps Android (Bước 8)

Bản đồ trong ứng dụng Android bình thường sử dụng `google_maps_flutter` (Maps SDK for Android). Vị trí xe và tuyến vẫn là **mẫu** cho tới Bước 9–11.

1. Google Cloud Console → APIs & Services → Enable APIs: chỉ bật **Maps SDK for Android** cho dự án ứng dụng này. Nếu key hiện có bật API khác, nên hạn chế lại.
2. APIs & Services → Credentials → chọn key Google Maps. Trong **Application restrictions**, chọn **Android apps** và thêm package `vn.bottaximeter.bot_taximeter_pro` cùng SHA-1 debug lấy từ báo cáo CI mới nhất: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`. Nếu chữ ký APK thay đổi, phải cập nhật SHA-1.
3. Trong **API restrictions**, chọn *Restrict key* rồi chỉ chọn **Maps SDK for Android**.
4. GitHub repository → Settings → Secrets and variables → Actions → *Secrets* → Secret `MAPS_API_KEY`. Không commit hoặc công bố key. Workflow đọc secret để chèn vào AndroidManifest.xml; không cần sửa file Android thủ công.
5. Thiết lập billing và **Budget/Alerts**, hạn ngạch và giám sát sử dụng trong Google Cloud. Lưu ý cảnh báo ngân sách không tự chặn chi tiêu.
6. Mở Actions, kiểm tra build APK rồi tải `debug-latest` trong Releases. Test CI sử dụng bản đồ giả nên **không** xác nhận key hoạt động hay chi phí thực tế.
7. Trên điện thoại mở Home/Tuyến đường/Đang chạy để xác nhận bản đồ thật. Nếu bản đồ trống, kiểm tra tên package + SHA-1 của APK, key Secret, API restriction, billing, Internet, Google Play Services.
8. Trong bản hiện tại: tọa độ `21.2741, 106.1946` và ba polyline là **demo**, không dùng để dẫn đường. GPS thực sẽ được tích hợp ở Bước 9.
9. Lịch sử/biên lai và preview Cài đặt vẫn dùng CustomPainter, không nạp bản đồ Google riêng, giảm map loads.

**An toàn:** Không sử dụng ứng dụng để xác nhận cước/định vị thật trước khi các bước tương ứng hoàn thành. Khóa ký debug nếu ở repo public có thể bị sao chép; nên để repo private.
