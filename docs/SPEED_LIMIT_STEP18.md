# BỘT TAXIMETER PRO — Bước 18: biển tốc độ và OSM tham khảo

**Ngày: 19/11/2026. Phạm vi:** tích hợp biển tham khảo trên Home và Trip cho APK Android thật; CI và widget test giữ biển mẫu cũ để không làm thay đổi smoke test đã ổn định.

## Cách sử dụng trên Redmi Note 12 Pro

1. Mở Home hoặc chuyến đi; bên trái bản đồ hiển thị tốc độ GPS và biển `--` khi chưa xác định. **Không coi số mẫu 60 km/h trong bản CI là giới hạn thật.**
2. Chạm biển. Chọn **khu vực đã kiểm tra** và **kiểu đường đã kiểm tra**. Trường mặc định là **Chưa rõ**; thiếu dữ liệu sẽ tiếp tục hiển thị `--`.
3. Nếu nhìn thấy biển hợp lệ trên đoạn đường, nhập tốc độ biển hoặc chạm mức nhanh. Chọn **Giữ đến khi tôi đổi** chỉ khi cần giữ ghi đè; nếu tắt, hệ thống đòi GPS và hủy giới hạn nhập tay khi rời bán kính khoảng 200 m. Lưu ý giới hạn theo đoạn có thể thay đổi trước mốc 200 m: người lái vẫn phải theo biển thật.
4. Tùy chọn: nhập URL **Overpass HTTPS được phép** và bấm **Tra cứu đường OSM (tham khảo)**. **Không có URL mặc định; CI không gọi mạng.** Cần GPS chính xác ≤15 m. Tra cứu chỉ thực hiện theo thao tác, không tự bám theo từng vị trí.
5. OSM chỉ trả gợi ý `oneway`, `lanes`, `maxspeed`: biển từ OSM chưa xác minh hiển thị ký hiệu `~` và **không** kích hoạt cảnh báo. OSM thiếu thẻ hoặc không đủ ngữ cảnh thì không đoán giới hạn.
6. Khi có giới hạn tài xế đã nhập hoặc quy tắc đủ thông tin, cảnh báo **trực quan** chỉ lên sau ít nhất 3 giây vượt liên tục với fix GPS ≤15 m, tuổi ≤5 giây; đứt quãng >4 giây phải đếm lại. Xung trạng thái tối đa 1 lần/15 giây; **chưa phát âm thanh hoặc rung** trong Bước 18. Không tự ghi phạt hoặc kết luận vi phạm.

## Giới hạn kỹ thuật và an toàn

- Để bảo vệ bộ test và tránh tự động hiển thị một giới hạn chưa kiểm chứng, Home/Trip trong môi trường mock CI vẫn dùng `HomeSpeedPanel` minh họa; trên Android thật dùng `RoadSpeedPanel`.
- Nguồn dữ liệu OSM không được xác minh, có thể thiếu, sai hoặc không chính xác cho làn/đường đôi; chỉ dùng để tham khảo. Provider dùng cache ô xấp xỉ 200 m, giới hạn 10 giây giữa các lượt gọi không cache, tối đa 64 kết quả RAM; **không có tự gọi nền**.
- Người dùng phải tự xác minh máy chủ Overpass được phép hoạt động và có chính sách sử dụng hợp lệ; không cấu hình máy chủ công cộng mặc định. Giao diện chưa tự động dò biển bằng ảnh hay nhập từ các tệp GeoJSON chưa được kiểm chứng.
- **Điểm hạn chế còn lại:** giao diện hiện tại chưa có chức năng ghi đè biển theo ID đoạn đường OSM/hướng di chuyển, mới dùng vòng 200 m hoặc giữ thủ công; chưa xác minh vị trí biển hiệu lực/rẽ/hết biển. Biển không thay thế biển ngoài đường.
- **Cảnh báo âm/rung** chưa được kết nối vì chưa có thử nghiệm độ tin cậy của dữ liệu từng tuyến; giữ nguyên module ngưỡng tốc độ cá nhân. Cần kiểm thử trên xe khi không gây phân tâm, tuyệt đối không cố ý chạy quá tốc độ.
- Không thay đổi schema SQLite, dữ liệu cước, BOT, phí chờ, PDF, VietQR, khóa debug, package Android, workflow CI hoặc 7 route.

## Phạm vi kiểm thử

- `test/road_context_provider_test.dart`: URL HTTPS, parse OSM và dữ liệu không hợp lệ, cache 200 m, giới hạn 10 giây, nguồn suy đoán không bật cảnh báo, GPS 3 giây và giãn xung 15 giây, widget sheet nhập biển.
- Widget test cũ của Home dùng giao diện mock nguyên trạng, không đổi nhãn chuẩn; CI Android 13 vẫn không truy cập GPS/Google Maps thật.
- Tại thời điểm commit: CI #31 cho Bước 17 đạt 4/4, **CI của Bước 18 chưa được xác minh**. Đọc báo cáo CI theo SHA sau khi Actions kết thúc.

## Bước tiếp theo

**Bước 19 được đề xuất:** triển khai SOS thật theo xác nhận người dùng, mở ứng dụng gọi điện và chia sẻ vị trí khi tài xế chủ động, không gửi bất kỳ dữ liệu nào tự động. Riêng các cải tiến tốc độ cần tiếp tục đánh giá ở lượt chuyên biệt về dữ liệu biển thực tế và âm/rung.
