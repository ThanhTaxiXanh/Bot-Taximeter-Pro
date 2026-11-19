# BỘT TAXIMETER PRO — Bước 19: SOS khẩn cấp

**19/11/2026.** Triển khai SOS theo mục 8 Master Prompt gốc. Không sửa đồng hồ cước, GPS tracking, SQLite, PDF, VietQR hoặc CI.

## Cách dùng trên Redmi Note 12 Pro

1. Mở **Cài đặt → SOS khẩn cấp**, xác nhận hoặc nhập số điện thoại SOS mong muốn, nhấn **Lưu số SOS**. Số mặc định là **113** (Công an); số này không tự động phát sinh cuộc gọi. Cấu hình lưu bằng `SharedPreferences` key `sos_phone`, độc lập nút Lưu cài đặt chung.
2. Khi cần hỗ trợ, mở màn **Đang chạy chuyến** và nhấn **SOS**. Màn hiện nút **Gọi [số SOS]**, **Chia sẻ vị trí**, **Đóng**. Chỉ mở hộp thoại này **không làm gì**.
3. Chạm **Gọi [số SOS]**, đọc lại số và bấm **Mở trình gọi điện** trong hộp xác nhận. `url_launcher` mở URI `tel:` ở chế độ `externalApplication`. Người dùng phải tiếp tục **bấm gọi trong ứng dụng điện thoại**. Không yêu cầu quyền CALL_PHONE và không tự thực hiện cuộc gọi.
4. Chạm **Chia sẻ vị trí**, xác nhận **Mở bảng chia sẻ**. Ứng dụng tạo văn bản có tọa độ GPS và link Google Maps, sau đó mở bảng chia sẻ chuẩn Android qua `share_plus`. Người dùng **tự chọn ứng dụng/người nhận/gửi**. Việc mở bảng chia sẻ không chứng minh đã gửi tới ai.
5. Nếu GPS chưa bật, vị trí chưa có, điểm GPS yếu (độ chính xác >25 m), cũ hơn 15 giây, hoặc là dữ liệu mock CI, tính năng không thể tạo nội dung chia sẻ và hiển thị thông báo. **Gọi SOS vẫn hoạt động độc lập với GPS.**

## Thư viện và tương thích build

- `url_launcher: 6.3.3` cho `tel:`; `share_plus: 11.1.0` cho bảng chia sẻ Android. Đã tham khảo tài liệu package pub.dev; chọn `share_plus` nhánh 11 do nhánh 12+ đòi AGP >=8.12.1/Kotlin 2.2.0, không tự thay workflow GitHub Actions.
- Không tạo AndroidManifest thủ công; repo dùng `ci/scripts/prepare_android.sh` sinh `android/` khi CI chạy. SOS không cần quyền CALL_PHONE, chỉ cần khả năng mở dialer ở Android. Không dùng `canLaunchUrl` để tránh yêu cầu Android query thừa.
- Dữ liệu chỉ có trong nội dung chia sẻ khi người dùng đồng ý. Không tự gửi SMS/email, không lưu lịch sử tọa độ trong SQLite/SharedPreferences và không gọi thêm API bản đồ để lấy vị trí.

## Kiểm thử

- Unit/widget: `test/trip_page_test.dart` xác nhận số mặc định 113, định dạng số hợp lệ, đổi/lưu số SOS, từ chối GPS yếu/cũ, không thực hiện khi chưa xác nhận, gọi `tel:`/chia sẻ qua backend giả khi đã xác nhận.
- CI #33 trước bước này **đạt 4/4**. CI của Bước 19 chỉ được xác nhận khi Issue #1 và log tại đúng commit cho kết quả analyzer, flutter test, APK và Android 13 đạt.
- Kiểm thử thật **chỉ khi xe đỗ**: cài APK đè không xóa dữ liệu, nhập số điện thoại thử nghiệm của chính mình (không gọi số khẩn cấp thật chỉ để test), mở trình gọi rồi thoát mà không thực hiện cuộc gọi; thử chia sẻ tọa độ đến một cuộc hội thoại riêng nhưng không bấm gửi. Không gọi số 113 trừ khi thật sự có tình huống khẩn cấp.

## Giới hạn

- Phụ thuộc ứng dụng điện thoại và ứng dụng hỗ trợ chia sẻ trên thiết bị. Nếu máy thiếu ứng dụng tương thích, hiển thị lỗi, không tự gọi/tự gửi.
- Tọa độ GPS là giá trị tham khảo từ điện thoại, không đảm bảo độ chính xác cứu hộ. Nếu khẩn cấp thật, ưu tiên trực tiếp gọi lực lượng chức năng và cung cấp thông tin vị trí rõ ràng.
- Không có hành vi gửi vị trí hoặc gọi điện nền; không yêu cầu đăng nhập và không lưu dữ liệu người nhận.

**Bước kế tiếp (đề xuất): 20 — bổ sung danh sách ngân hàng VietQR và cache an toàn, chỉ sau khi người dùng tiếp tục.**
