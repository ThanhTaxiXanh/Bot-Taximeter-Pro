# Bước 28 — Phân bố biển báo theo viewport và kiểm thử nhập SQLite

**Ngày 20/11/2026.** Mốc đầu vào: CI #48, commit `40c6ae1`, Issue #1 đạt 4/4; tag `debug-latest` tại đầu bước trùng commit này. Bản APK của Bước 28 **phải chờ báo cáo CI của commit mới**; không coi APK cũ là bản đã tích hợp tối ưu Bước 28.

## Phát hiện và xử lý

- Hai tệp gốc đã kiểm checksum SHA-256: `traffic_signs.csv` (151.228 bản ghi, 7.501.107 byte, SHA-256 `bed99913c88b1da495cc9b25444f0bf495ac9c3c059b0071f888d623bcadd9d9`) và `speed_limit_signs.csv` (38.757 bản ghi, 1.434.994 byte, SHA-256 `432f6d3251b315b780af71cd7250d2243f78ce7b2aedf5225bdf75e39710238e`). Các dòng có đủ lần lượt 9 và 6 trường CSV.
- Truy vấn cũ chỉ lấy 800 điểm gần tâm viewport rồi gom vào lưới. Thử với một vùng ví dụ ở Bắc Giang (`lat 21.10–21.48`, `lon 106.03–106.46`) trên SQLite Python và chính CSV thật: 800 ứng viên cũ tập trung vào **12** ô; lấy 1 ứng viên/ô trên lưới **8 x 4** mới phủ **32** ô có dữ liệu. Đây là thử nghiệm mô phỏng cục bộ, không phải bằng chứng hiệu năng Redmi.
- `ImportedRoadSigns.markersInBounds` chuyển sang 32 truy vấn `LIMIT 1` theo ô viewport và index SQLite có sẵn `(lat,lon)`. Tối đa 32 ghim màu cam, không cần tải 800 điểm rồi sắp xếp theo tâm. Mỗi ô tối đa 1 biển nên **không thể hiện hết mọi biển đồng vị trí**; phóng to để tăng chi tiết.
- Thêm `ImportedRoadSigns.forTesting(path)` và `closeForTesting()` để bài integration test dùng database độc lập. Ứng dụng vẫn dùng singleton và tệp `imported_traffic_signs.db` cũ, không thay schema, không xóa dữ liệu trước đây.
- `integration_test/imported_road_signs_test.dart` chạy trên SQLite Android thực: nhập 1.280 dòng giả lập qua luồng XFile, kiểm tra 32 ô, vùng trống, header lỗi không mất tập đang có, đóng/mở lại vẫn còn dữ liệu, và nhập tệp tốc độ thay thế tập cũ. Không lấy 1.280 dòng làm bằng chứng đã nhập đủ 151.228 dòng trên Redmi.

## Checklist nghiệm thu trên Redmi Note 12 Pro

1. Trước cài, ghi số cuốc và tổng doanh thu. Chỉ tải APK khi **Issue #1 cho commit mới đạt 4/4** và Release `debug-latest` trỏ đúng commit. Cài **đè**, không gỡ hoặc xóa dữ liệu.
2. Tải `traffic_signs.csv` nguyên gốc (ưu tiên) vào Downloads. Home → biểu tượng **Nhập CSV** cạnh **Biển tham khảo** → chọn tệp. Chờ thông báo **Đã lưu 151228 biển** và chip **Biển: 151228**.
3. Chạm bật/tắt chip; kéo/zoom bản đồ trên vùng có dữ liệu, xác nhận không quá 32 ghim màu cam, ghim phân tán theo vùng nhìn; chạm ghim xem ID, mã loại, mã hướng, giá trị và meta. Ở zoom gần có thể thấy ít ghim hơn, không phải lỗi tự động.
4. Tắt mạng, đóng/mở app, bật lại chip; số bản ghi và ghim vẫn còn. Kiểm tra GPS/nhãn đường hoạt động độc lập (chỉ hiện tên đường khi có kết quả HTTPS được phép).
5. Kiểm tra lịch sử và doanh thu bằng số liệu ghi trước cập nhật; thử màn PDF/VietQR/SOS/LED khi xe đỗ. **Không chuyển tiền để thử QR**, không thực hiện gọi SOS khẩn cấp không có lý do.
6. Nếu lệch số biển, chậm bất thường, mất ghim hoặc mất lịch sử: ghi số hiện trên chip, vùng/zoom, nội dung thông báo và ảnh màn hình. **Không Clear storage hoặc gỡ app** trước khi chẩn đoán.

## Ranh giới an toàn

- CSV là dữ liệu tự thu thập và giữ trường hướng thô; không dùng làm căn cứ tốc độ hợp pháp hay tự động phát cảnh báo vượt tốc độ.
- Không đổi `bot_taximeter.db`, GPS lọc nhiễu, giá cước, VietQR, PDF, SOS, LED, Android package, Google Maps key, khóa ký hoặc CI workflow.
- CI chỉ kiểm thử luồng nhập SQLite bằng dữ liệu giả lập; **nghiệm thu đầy đủ 151.228 dòng và hiệu năng/độ phủ trên Redmi vẫn đang chờ**.

**Bước tiếp theo: 29 — xử lý kết quả CI Bước 28 và phản hồi nghiệm thu Redmi.**
