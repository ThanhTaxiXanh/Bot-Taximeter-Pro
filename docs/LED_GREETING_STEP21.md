# BỘT TAXIMETER PRO — Bước 21: LED chào khách

**Ngày 19/11/2026.** Theo Master Prompt mục 8, bổ sung màn hình LED chữ lớn mở từ Cài đặt (bước tính năng cuối).

## Trải nghiệm trên điện thoại

1. Khi xe đã dừng an toàn, mở **Cài đặt → Giao diện**. Nhập câu chào trong ô **Câu chào LED** (mặc định `Xin chào quý khách!`).
2. Chọn **Kích thước chữ**: Nhỏ, Vừa hoặc Lớn. Nhấn **Mở màn hình LED chào khách**.
3. Màn hình LED xuất hiện che toàn bộ giao diện ứng dụng thông thường, nền navy đậm với chữ lớn cyan, tự điều chỉnh để vừa màn hình. Nút đóng tại góc trên phải; phím Back của Android cũng có thể quay lại Cài đặt.
4. Màn LED là **xem trước**: khi thay câu chào/cỡ chữ chưa lưu, màn vẫn xem được nhưng không tự lưu. Muốn giữ giá trị cho lần sau, quay về và bấm **Lưu cài đặt**; dữ liệu giữ trong `SharedPreferences` với key cũ `led_greeting`, `font_size`.
5. Nội dung trống hiển thị mặc định; ký tự xuống dòng/điều khiển đổi thành khoảng trắng; màn LED chỉ hiển thị tối đa 120 ký tự Unicode. Ô nhập và giá trị đã lưu không bị cắt hoặc thay đổi bởi chức năng xem trước.

## Thiết kế/kỹ thuật

- Tệp mới `lib/features/settings/presentation/led_greeting_page.dart`: `LedGreetingPage` và `LedGreetingLaunchButton`.
- Không tạo route GoRouter thứ tám, dùng `Navigator.push(MaterialPageRoute)` tạm thời để giữ **7 route hiện có** và dễ quay lại Cài đặt.
- Cỡ chữ thiết kế: `Nhỏ=64`, `Vừa=88`, `Lớn=120`; `FittedBox(fit: BoxFit.scaleDown)` để co chữ khi màn hẹp hoặc nội dung dài, không cuộn/chạy chữ và không tải font mới.
- Màu nền và chữ tái dùng `AppColors` đã có. Không yêu cầu quyền Android, không dùng GPS, không truy cập API, không thay SQLite/VietQR/giá cước/SOS.
- Có nút Đóng luôn hiển thị, không buộc ẩn thanh điều hướng Android nhằm tránh bị kẹt trên màn hình khi thử thực tế.

## Kiểm thử

- `test/led_greeting_test.dart`: chuẩn hóa câu chào, giới hạn hiển thị, ba cỡ chữ; mở từ Settings với giá trị lưu trên thiết bị; đóng quay về; bản xem trước không tự ghi `SharedPreferences`; widget hoạt động tại viewport 360×640 và 430×940.
- CI #37 trước bước này đạt đầy đủ 4/4. Kết quả CI của commit Bước 21 **chưa xác nhận** khi tạo mã.
- Trên Redmi Note 12 Pro: chỉ thử khi xe dừng, kiểm tra dấu tiếng Việt, màu sắc, cỡ chữ, Back/Đóng, sau đó lưu và mở lại Cài đặt. Cần kiểm tra riêng khả năng đổi hướng màn hình do Android có thể khóa xoay.

## Giới hạn

- Chữ dài sẽ co để giữ toàn bộ nội dung trong màn hình, vì vậy không nhất thiết to bằng chữ ngắn.
- Đây là màn hình chào khách, không phải đèn LED vật lý, không điều khiển màn hình thứ hai và không tự gửi tin.

**Bước tiếp theo đề xuất: 22 — tối ưu pin, rà soát Google Maps/README**, chỉ sau khi CI Bước 21 đạt và người dùng yêu cầu tiếp tục.
