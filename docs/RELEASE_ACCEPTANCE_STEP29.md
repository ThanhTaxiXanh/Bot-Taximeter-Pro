# Bước 29 — Xác minh phát hành debug và cổng nghiệm thu Redmi

**Ngày:** 20/11/2026. **Đối tượng:** BOT TAXIMETER PRO (debug APK cho thiết bị cá nhân, không phải đồng hồ taxi kiểm định).

## 1. CI và Release đã kiểm chứng

- Nhánh `main`: commit `428cdf3bd3080369c8479483d9e702ff8064e398` (mã nhập biển Bước 28).
- Báo cáo GitHub Issue #1: **CI #49**, run `44753921725`, cả 4 hạng mục **Đạt**.
- Đã đọc job logs: `flutter analyze` không có error/warning (còn lint mức info), **122/122 unit/widget test đạt**, APK debug arm64 đã build, **13/13 integration Android 13 đạt**. Bài `integration_test/imported_road_signs_test.dart` được chạy và đạt.
- Tag `debug-latest` và Release **APK debug mới nhất (#49)** trỏ cùng SHA `428cdf3...`; asset `BOT-TaxiMeterPro-debug.apk` dung lượng **113.728.076 byte** tại lần xác minh. Chưa đối chiếu hash SHA-256 của asset APK khi tải về máy.
- Khóa ký debug SHA-1 trong Issue #1: `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`. Android package phải giữ `vn.bottaximeter.bot_taximeter_pro`.
- Nguồn CSV do người dùng cung cấp: `traffic_signs.csv` **151.228** bản ghi, SHA-256 `bed99913c88b1da495cc9b25444f0bf495ac9c3c059b0071f888d623bcadd9d9`; `speed_limit_signs.csv` **38.757** bản ghi, SHA-256 `432f6d3251b315b780af71cd7250d2243f78ce7b2aedf5225bdf75e39710238e`. Cả hai đã đối chiếu lại checksum và số dòng 20/11/2026.

## 2. Checklist thao tác trên Redmi Note 12 Pro

**Khi xe đã dừng**, thực hiện lần lượt:

1. Mở ứng dụng hiện có → **Lịch sử/Doanh thu** → ghi số cuốc, tổng doanh thu và cuốc mới nhất; nếu đang có cuốc đang chạy, hoàn tất hoặc xử lý trạng thái trước khi cập nhật.
2. Mở https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/releases/tag/debug-latest ; xác nhận tiêu đề **#49**, commit `428cdf3` và tên asset `BOT-TaxiMeterPro-debug.apk`. Tải và **cài đè**, **không gỡ app**, không Clear storage. Nếu Android từ chối vì khác chữ ký, dừng thay vì gỡ.
3. Mở lại → **Lịch sử/Doanh thu**, đối chiếu số liệu cũ. Cài đè không được xóa `bot_taximeter.db` hoặc `imported_traffic_signs.db`.
4. Tải `traffic_signs.csv` nguyên bản về Downloads → Home → nút **Nhập CSV** cạnh **Biển tham khảo** → chọn tệp. Kỳ vọng `Biển: 151228`. **Không** nhập `speed_limit_signs.csv` sau đó vì tệp sau sẽ **thay thế** bộ tổng hợp.
5. Bật **Biển tham khảo**; pan/zoom khu vực có dữ liệu, thử zoom rộng/hẹp, xác nhận tối đa **32** marker cam, phân bố trải theo vùng nhìn. Chạm marker để kiểm tra ID, loại, hướng và giá trị thô.
6. Đóng app, tắt mạng, mở lại và bật lớp biển; số lượng và marker phải còn. Sau đó kiểm tra GPS, nhãn đường khi có dịch vụ geocoding được phép; không giả định mọi tên đường đều có dữ liệu.
7. Kiểm tra cuốc mẫu với GPS/cước, mở biên lai PDF, kiểm tra VietQR bằng cách quét **không chuyển tiền**, thử màn LED; không thực hiện cuộc gọi khẩn cấp SOS thật nếu không có sự cố.

## 3. Mẫu báo cáo nghiệm thu gửi lại

```text
BỘT TAXIMETER PRO — REDMI BƯỚC 29
APK: Build #49 / SHA 428cdf3 / cài đè thành công: Có-Không
Lịch sử trước cập nhật: __ cuốc / __ đ
Lịch sử sau cập nhật: __ cuốc / __ đ
CSV đã chọn: traffic_signs.csv
Số lượng trên chip sau nhập: __
Khởi động lại/offline còn dữ liệu: Có-Không
Pan/zoom bản đồ và marker (tối đa 32): Đạt-Không
GPS và nhãn đường: Đạt-Không-Chưa cấu hình
PDF / VietQR / SOS / LED: __
Thông báo lỗi, ảnh màn hình (nếu có): __
```

## 4. Quyết định kỹ thuật

- **Bước 29 là cổng xác minh Release/CI và hướng dẫn nghiệm thu, không thay đổi Dart hay dữ liệu ứng dụng.** Commit tài liệu Markdown không kích hoạt GitHub Actions vì workflow bỏ qua `**.md`.
- CI Android 13 chạy với CSV tổng hợp **giả lập 1.280 hàng**, không chứng minh được nhập thật **151.228 hàng** hoặc hiệu năng bộ chọn tệp/SQLite trên Redmi. Không đánh dấu hoàn tất nghiệm thu trước khi có số liệu thực tế.
- Ghim tham khảo CSV **không** chứng minh giới hạn tốc độ đang có hiệu lực. Không đưa dữ liệu biển vào cảnh báo vượt tốc độ, định tuyến hay tính cước.
- Nếu có sự cố, **ưu tiên giữ dữ liệu máy** và chẩn đoán bằng thông báo/ảnh màn hình; không cài lại từ đầu hoặc xóa storage.

**Bước tiếp theo: 30 — xử lý kết quả nghiệm thu Redmi / lỗi thực tế nếu có; không tự ý mở rộng tính năng.**
