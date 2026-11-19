# BỘT TAXIMETER PRO — Bước 15 (phần cơ sở VietQR offline)

## Phạm vi

Chỉ triển khai **tạo yêu cầu chuyển khoản** theo chuẩn VietQR/NAPAS247 bằng mã QR tạo ngay trên thiết bị. Không có API ngân hàng, không gửi lệnh chuyển tiền, không có webhook hoặc đối soát giao dịch, **không tự xác nhận tiền đã nhận**. Cước GPS vẫn chỉ để tham khảo, chưa phải đồng hồ taxi được kiểm định.

Tham khảo đặc tả định dạng VietQR v1.0 (NAPAS247): https://kiemtrabank.com/documents/QR_Format_T%26C_v1.0_VN_092021.pdf và thông tin chính thức từ NAPAS: https://napas.com.vn/napas-va-cac-ngan-hang-chinh-thuc-ra-mat-thuong-hieu-vietqr-va-dich-vu-chuyen-tien-nhanh-napas247-bang-ma-qr-182755.htm

## Bật thủ công

1. Mở **Cài đặt → Thanh toán**, nhập **ngân hàng**, **chủ tài khoản**, **số tài khoản nhận tiền** và **BIN ngân hàng 6 số** đúng theo thông tin ngân hàng cung cấp. Mã BIN không thể suy ra một cách đáng tin cậy chỉ từ tên ngân hàng.
2. Bật **Cho phép tạo VietQR chuyển khoản**, sau đó nhấn **Lưu cài đặt**. Mặc định là **TẮT**. Không nhập mã PIN, mật khẩu, OTP hoặc token API.
3. Hoàn thành chuyến và lưu vào SQLite; chọn **Chuyển Khoản** trên Biên lai. Kiểm tra người nhận và số tiền GPS tham khảo, rồi chủ động bấm **Hiển thị QR chuyển khoản**.
4. Bên chuyển tiền cần tự kiểm tra thông tin tài khoản/số tiền hiển thị trong ứng dụng ngân hàng, rồi xác nhận giao dịch bên phía ngân hàng. Tài xế chỉ xác minh tiền đã về qua **ngân hàng của mình**.

Biên lai mẫu không bao giờ được tạo QR chuyển tiền. Nếu thiếu hoặc không hợp lệ BIN/tài khoản/giá trị tiền gốc của chuyến, không hiện nút tạo QR. Số tiền lấy từ `CompletedTrip.fareVnd` đã lưu, **không** suy ra từ chữ hiển thị trên UI.

## Định dạng mã

- NAPAS GUID: `A000000727`, template `38`, ngân hàng BIN `01.00`, tài khoản `01.01`, mã dịch vụ `QRIBFTTA`.
- Loại mã động `01=12`, đơn vị tiền `53=704` (VND), số tiền nguyên dương `54`, quốc gia `58=VN`; nội dung ASCII `62.08` gồm mã cuốc rút gọn.
- CRC16/CCITT-FALSE, polynomial `0x1021`, init `0xFFFF`, kết thúc `6304` và bốn ký tự hex.
- Giới hạn phần mềm: BIN đúng 6 chữ số, số tài khoản 6–19 chữ số, tiền yêu cầu từ 1 đến dưới 500.000.000 VND; **ngân hàng có thể áp dụng giới hạn thấp hơn**.
- Payload sinh offline bằng Dart; `qr_flutter` render QR, **không chèn logo vào QR thật** để giảm lỗi quét.

## Quyền riêng tư và giới hạn kiểm chứng

- Thông tin tài khoản ngân hàng vốn đã được lưu trong `SharedPreferences` từ bước trước; BIN và cờ bật VietQR cũng được lưu tại đây. Đây **không phải nơi lưu thông tin xác thực hoặc bí mật ngân hàng**.
- Mã QR chứa BIN và số tài khoản, là thông tin người quét sẽ nhìn thấy. Không tự gửi thông tin tài khoản/chuyến cho bên thứ ba.
- Bật mã không đồng nghĩa tài khoản được ngân hàng xác minh hoặc đã nhận tiền.
- Không ghi nhận doanh thu đã thanh toán, không tự thay đổi trạng thái biên lai, không phát hành hóa đơn điện tử.
- CI kiểm thử CRC mẫu tài liệu, tính chính xác payload, input sai, mặc định tắt, yêu cầu thao tác chủ động và chế độ demo. **Cần kiểm tra quét QR bằng ứng dụng ngân hàng hợp lệ trên Redmi Note 12 Pro trước khi sử dụng thật**; có thể thử ở mức không thực hiện chuyển khoản.

**Bước 15 chưa được xác nhận toàn bộ** vì Master Prompt gốc chưa có trong repository/tệp dự án có thể truy cập. Không triển khai phần thanh toán tự động hoặc đối soát khi chưa có hợp đồng/API và quy trình bảo mật phù hợp.
