# BỘT TAXIMETER PRO — Bước 14 (phần biên lai PDF)

## Phạm vi triển khai

Màn **Biên lai chuyến đi** hỗ trợ ba thao tác do tài xế chủ động bấm:

- **In biên lai:** mở hộp thoại in Android qua `Printing.layoutPdf`.
- **Chia sẻ:** mở trình chia sẻ của Android và đính kèm tệp PDF.
- **Xuất PDF:** mở trình chia sẻ của Android để người dùng chọn nơi lưu (ví dụ Files/Drive, tùy ứng dụng đã cài). Không tuyên bố đã lưu tệp trước khi Android hoàn tất lựa chọn.

Chỉ thực hiện với dữ liệu chuyến `isRecorded=true` đã hoàn thành và được lưu bởi Bước 13. Màn dữ liệu mẫu không được xuất PDF thật. File đặt tên `BOT-TaxiMeterPro-<ID>.pdf`, loại bỏ ký tự bất thường khỏi tên.

## Nội dung và giới hạn

Trang A4 có mã chuyến, mốc bắt đầu/kết thúc, quãng đường GPS, thời gian, thời gian chờ, tiền chờ, phí BOT và tổng cước. Chữ tiếng Việt được dựng thành ảnh PNG bằng **Canvas của Flutter** rồi chèn vào PDF bằng thư viện `pdf`. Cách này làm việc offline, không tải font qua mạng. **Đổi lại văn bản trong PDF là ảnh, không tìm kiếm hoặc sao chép từng chữ được.**

Bắt buộc có cảnh báo trên tờ biên lai:

- **BIÊN LAI CƯỚC GPS THAM KHẢO**
- **KHÔNG PHẢI HÓA ĐƠN · CHƯA KIỂM ĐỊNH**
- Không xác nhận đã nhận tiền hoặc chuyển khoản.

Không xuất tên/địa chỉ khách khi chưa thu thập được. Không thêm dữ liệu ngân hàng, API key hoặc QR thanh toán vào PDF. Mục VietQR đang có vẫn là **DEMO · KHÔNG THANH TOÁN**. Tuyệt đối không suy đoán trạng thái giao dịch từ việc khách đã mở/chia sẻ PDF.

## Kiểm thử

- `test/receipt_pdf_test.dart`: từ chối bản mẫu, kiểm tra làm sạch tên file và tạo PDF `%PDF-` offline.
- `test/step7_pages_test.dart`: kiểm tra nút “Xuất PDF” của biên lai mẫu không tạo file.
- `integration_test/receipt_pdf_test.dart`: tạo PDF thực tế bằng Flutter Canvas trên Android 13.
- Giữ nguyên 7 ca smoke chuẩn và integration test SQLite native của Bước 13.

## Kiểm tra trên Redmi Note 12 Pro

1. Cài đè APK debug mới lên bản trước, **không gỡ ứng dụng** để giữ SQLite.
2. Hoàn tất một cuốc thử, mở Biên lai hoặc chọn Xem chi tiết từ Lịch sử.
3. Chọn **Xuất PDF**, lưu file bằng ứng dụng được Android hỗ trợ, mở file và kiểm tra chữ có dấu không lỗi, không bị cắt.
4. Chọn **In biên lai**, kiểm tra Android Print Preview; không cần có máy in.
5. Chọn **Chia sẻ**, kiểm tra trình chia sẻ xuất hiện nhưng không gửi tệp ngoài khi chưa muốn.
6. Mở một biên lai mẫu, nhấn Xuất PDF: phải bị chặn, không tạo tệp thật.

**Chưa hoàn tất toàn bộ Bước 14** khi chưa đối chiếu nguyên văn Master Prompt gốc và chưa chạy đầy đủ kiểm thử trên thiết bị thật. Không triển khai VietQR nhận tiền thật trong phần này.
