# BỘT TAXIMETER PRO — Bước 23: biên bản nghiệm thu tổng thể

**Ngày lập:** 19/11/2026. **Ứng dụng:** `vn.bottaximeter.bot_taximeter_pro`, Flutter, GitHub Actions, dùng trên Redmi Note 12 Pro (Android 13). **Căn cứ:** Master Prompt mục 1B, 2, 3, 6, 8, 10 và các bước 9–22 của dự án.

## 1. Trạng thái nghiệm thu

- [x] **Mốc kiểm thử trước bước 23:** CI #41, SHA `3669dd4`, toàn bộ 4 hạng mục đạt theo GitHub Issue #1: analyze, unit/widget test, APK debug arm64, Android 13 integration.
- [x] **CI Bước 23:** CI #43 commit `c473bb4` đạt **4/4** theo Issue #1 (analyze, flutter test, APK, UI Android 13). CI #42 có 1 test thời gian chờ bị lỗi và đã sửa trước CI #43; cần đọc lại báo cáo nếu phát sinh commit mới.
- [ ] **Điện thoại thật:** chưa có bằng chứng đã kiểm thử GPS, Android background, key Maps, PDF, SQLite dữ liệu người dùng và VietQR thật; không đánh dấu đạt trước khi người dùng thử.
- [ ] **Nghiệm thu vận hành:** chỉ hoàn tất sau khi các mục thiết yếu dưới đây được tài xế kiểm tra trên thiết bị thực; đây vẫn là đồng hồ cước **tham khảo, chưa kiểm định**.

## 2. Kiểm thử tự động bổ sung trong bước 23

- `integration_test/sqlite_upgrade_test.dart`: trên Android 13 dùng `sqflite` thật, tạo các DB **độc lập** v1/v2, chèn snapshot `waiting`, thêm chuyến đã hoàn thành ở v2. Mở bằng **cùng migration của `TaximeterDatabase`**, kiểm tra dữ liệu cũ còn nguyên, bảng `banks` dùng được; kiểm tra cài mới v3 tạo đủ ba bảng. Xóa DB thử nghiệm sau mỗi ca; **không sửa `bot_taximeter.db` người dùng**.
- `test/release_acceptance_test.dart`: chuỗi cước chuyến → lưu bản ghi → biên lai → mã VietQR offline; xác nhận 30.500 đ làm tròn **xuống** 30.000 đ, sau đó mới cộng 5.000 đ BOT, tổng biên lai/payload đều **35.000 đ**, lưu cuốc không bị nhân đôi.
- `lib/features/history/data/taximeter_database.dart` chỉ tách hàm mở schema `openAtPath` cho phép test DB riêng; chính ứng dụng mở DB mặc định bằng hàm đó. Không thay câu lệnh SQL/schema hay version 3; giữ khóa debug và workflow.

## 3. Checklist nghiệm thu trên Redmi — chỉ thao tác khi xe đỗ

### A. Cài đè, dữ liệu và quyền

- [ ] Trước cập nhật: chụp **màn Lịch sử** và ghi số chuyến/tổng tiền; đang có chuyến thì **kết thúc/lưu** hoặc ghi lại dữ liệu trước.
- [ ] Tải APK mới nhất chỉ sau khi **Issue #1** báo đạt 4/4 đúng SHA. **Cài đè, không gỡ app, không xóa dữ liệu, không Clear storage**.
- [ ] Mở app, kiểm tra lịch sử và cài đặt cũ còn đúng. Không yêu cầu tạo tài khoản, đăng nhập hay quyền không cần thiết.
- [ ] Nếu có snapshot đang chạy, thử xác nhận **Khôi phục chuyến đang chạy?**; cước không tự cộng thời gian app đóng, không tự nối GPS nhảy quãng đường. Chỉ dùng chuyến thử, không thử khi có khách.
- [ ] Kiểm tra bản đồ Android thật hiển thị, khóa Maps được giới hạn package `vn.bottaximeter.bot_taximeter_pro` và SHA-1 từ báo cáo CI. Không dán secret/API key vào chat.

### B. GPS, pin và cước

- [ ] **Home:** bật GPS thủ công; chờ fix chính xác, không hiển thị marker giả nếu thiếu GPS. Ra nền/trở lại: luồng GPS xem trước dừng; nếu muốn xem xe thì bật lại thủ công.
- [ ] **Đang chạy chuyến:** khi bắt đầu sẽ hỏi GPS/thông báo; kiểm tra có foreground notification. Đưa app ra nền ngắn khi xe đỗ, quay lại **không mất chuyến**; không tắt GPS chuyến vì chức năng tiết kiệm pin Home.
- [ ] Với chuyến thử ở khu vực an toàn, kiểm tra khoảng cách tăng hợp lý, không cộng quãng đường khi GPS yếu/nhảy sai. **Không thao tác màn hình khi đang điều khiển xe**.
- [ ] Dùng chuyến thử để kiểm tra các ngưỡng 1,5 km/30 km/50 km, 5 phút chờ miễn phí, BOT sau làm tròn và quy tắc **dư đúng 500 đồng làm tròn xuống**; đối chiếu bảng giá đã cài.
- [ ] Sau **Kết thúc**, kiểm tra GPS và wakelock đã dừng; thông báo foreground không còn. Quan sát mức hao pin thực tế qua nhiều chuyến; CI không đo được phần trăm tiết kiệm.
- [ ] Trên Xiaomi/Redmi, nếu hệ thống dừng GPS nền, kiểm tra **Pin → Không hạn chế**, Vị trí chính xác, quyền Thông báo. Không tự cấp miễn tối ưu pin.

### C. Biên lai, VietQR, ngân hàng

- [ ] Màn **Lịch sử & Doanh thu** chỉ thống kê cuốc đã lưu, chi tiết cuốc mới khớp tổng cước/BOT/phí chờ.
- [ ] Tạo **PDF** từ một cuốc đã lưu: có tiếng Việt đúng dấu, có cảnh báo **chưa kiểm định/không phải hóa đơn**, số tiền không khác biên lai. Thử chia sẻ/in nếu có ứng dụng phù hợp.
- [ ] Tắt mạng rồi vào Cài đặt → Thanh toán: danh sách ngân hàng seed/cache vẫn xem được; chọn ngân hàng chỉ điền tên và BIN. Kiểm tra chủ tài khoản/số TK **không bị ghi đè**; bấm **Lưu cài đặt** nếu muốn giữ.
- [ ] Khi có mạng, chỉ bấm **Làm mới danh sách từ VietQR** nếu cần. Nếu mạng lỗi, danh sách cũ phải được giữ.
- [ ] Với cuốc đã lưu và VietQR được bật rõ ràng: xem mã chuyển khoản, kiểm tra BIN/đích nhận/số tiền/nội dung với **ứng dụng ngân hàng**; **không chuyển tiền thử** nếu chưa xác minh tài khoản. QR không phải xác nhận đã nhận tiền.

### D. SOS, LED, tốc độ và bản đồ

- [ ] Chạm **SOS**: không tự gọi/chia sẻ trước khi xác nhận; số mặc định 113 hoặc số đã cấu hình, không thực hiện cuộc gọi thật khi chỉ thử giao diện.
- [ ] Chọn **Chia sẻ vị trí** chỉ sau xác nhận; nếu GPS không có/đã cũ thì không gửi vị trí giả.
- [ ] **LED:** nhập câu chào tiếng Việt, mở màn hình chào, thử 3 cỡ chữ, Đóng/Back. Xem trước **không tự lưu**; chỉ lưu khi bấm **Lưu cài đặt**.
- [ ] Cảnh báo tốc độ và biển báo mẫu không tự nhận là giới hạn thực; chỉ tham khảo theo cấu hình đã chọn.
- [ ] Bản đồ 2D/3D, Follow, traffic: không thêm Map ID/Places/Routes/Geocoding trả phí trong app; xem Cloud Billing Reports/SKU thực tế và Budget Alerts (cảnh báo ngân sách **không tự khóa phí**).
- [ ] Tìm địa chỉ/định tuyến: khi chưa cấu hình endpoint hợp lệ, không tự gửi vị trí đến dịch vụ công cộng. Khi cấu hình, dùng máy chủ HTTPS được phép và chỉ gọi theo thao tác.

## 4. Cách báo kết quả về cuộc trò chuyện

Có thể gửi lại: **`CI #...: 4/4 | Redmi: A..., B..., C..., D... | Lỗi: ...`**. Chỉ cần nêu các mục lỗi và ảnh/chữ hiện trên màn; **không chia sẻ số tài khoản, số điện thoại riêng, vị trí thật, khóa API hoặc OTP**.

### Tiêu chuẩn hoàn tất

1. CI đúng commit đạt 4/4 theo Issue #1.
2. Không mất lịch sử, snapshot, giá cước hoặc cấu hình sau cài đè.
3. Chuyến thử giữ dữ liệu/cước đúng, GPS khi đang có chuyến không bị tắt sai khi app ra nền.
4. VietQR, PDF, SOS và LED đúng điều kiện xác nhận, không tự gửi dữ liệu/gọi điện/chuyển tiền.
5. Người dùng đã kiểm tra bản đồ, GPS, pin và Google Cloud trên thiết bị/tài khoản của mình.

**Chưa đủ bằng chứng để ký nghiệm thu trên điện thoại** cho đến khi các mục thử thực địa được xác nhận. Không phát hành công khai ứng dụng dưới danh nghĩa đồng hồ taxi được kiểm định.
