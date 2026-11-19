# BỘT TAXIMETER PRO — Bước 20: danh sách ngân hàng VietQR

**Ngày:** 19/11/2026. **Căn cứ Master Prompt:** mục 8 yêu cầu tải danh sách ngân hàng/BIN từ VietQR, cache SQLite và JSON seed dùng lần đầu khi mất mạng.

## Hướng dẫn trên điện thoại

1. **Cài đè APK mới**; không gỡ phiên bản cũ hoặc xóa dữ liệu trước khi kiểm tra bảng lịch sử và snapshot. Ứng dụng tự nâng cơ sở dữ liệu `bot_taximeter.db` từ v2 lên v3.
2. Mở **Cài đặt → Thanh toán → Chọn ngân hàng trong danh sách**. Danh sách hoạt động offline: lần đầu đọc `assets/data/vietqr_banks_seed.json`, rồi cache SQLite. Có thể tìm ngân hàng theo tên hoặc BIN.
3. Khi chọn, ứng dụng chỉ điền hai ô **Ngân hàng** và **BIN ngân hàng (6 số)**. Không thay đổi **Chủ tài khoản**, **Số tài khoản**, trạng thái cho phép VietQR hoặc cước chuyến. Phải nhấn **Lưu cài đặt** để ghi hai trường đã chọn.
4. Khi có internet, bấm **Làm mới danh sách từ VietQR** để gọi GET `https://api.vietqr.io/v2/banks`. Không có truy vấn tự động mỗi khi mở Settings; CI/widget test không gọi internet. Danh sách cập nhật là nguồn tham khảo, có thể thay đổi theo nhà cung cấp.
5. Nếu mạng lỗi, dữ liệu API không hợp lệ, không đủ ngân hàng, hoặc SQLite ghi lỗi, **không xóa cache đang có**. Nếu chưa có cache, vẫn có seed (18 ngân hàng) để chọn khi offline.
6. Trước khi tạo QR thanh toán, đối chiếu chính xác **BIN, tên ngân hàng, chủ tài khoản và số tài khoản** trong ứng dụng ngân hàng. Quét mã chỉ là yêu cầu chuyển khoản; ứng dụng không xác minh giao dịch đã đến.

## Lược đồ và bảo toàn dữ liệu

- SQLite `TaximeterDatabase` nâng `version: 2` → `version: 3`; `onUpgrade(oldVersion < 3)` tạo bảng `banks` mới bằng `CREATE TABLE IF NOT EXISTS`. Bảng có `bin TEXT PRIMARY KEY`, `short_name`, `full_name`, `bank_code`. Bảng chuyến hoàn thành `completed_trips` và `trip_snapshots` vẫn giữ nguyên.
- Repository chỉ cache **thông tin công khai ngân hàng**, không lưu số tài khoản, mã OTP, mật khẩu, số dư hay lịch sử thanh toán vào bảng `banks`.
- Khi API trả về dữ liệu hợp lệ, việc thay toàn bộ danh sách chạy trong một SQLite transaction; nếu lỗi sẽ rollback. Khi API không hợp lệ hoặc kết nối thất bại, không gọi thao tác replace.
- Không thêm package mới, không chỉnh CI, package Android, Maps API key, VietQR payload, PDF, GPS hay SOS.

## Dữ liệu/nguồn và giới hạn

- Tài liệu VietQR: https://www.vietqr.io/api-bank
- API: https://api.vietqr.io/v2/banks
- Seed chỉ là **bản dữ liệu tham khảo** 18 ngân hàng phổ biến được đối chiếu từ danh sách API tại ngày 19/11/2026; có thể lỗi thời sau đó. Không tự phỏng đoán BIN mới hoặc xác nhận tài khoản dựa vào tên ngân hàng.
- Tài liệu VietQR khuyến nghị làm mới danh sách theo ngày; ứng dụng cho phép làm mới khi người dùng chủ động, không tự tạo lưu lượng mạng hoặc tự quyết định thay dữ liệu offline.
- `transferSupported == 0` bị loại khỏi danh sách chọn chuyển khoản. Chỉ dùng BIN 6 chữ số, tên và code hợp lệ; đầu ra không được coi là kiểm chứng tên người nhận.

## Kiểm thử và trạng thái

- CI #36 (trước Bước 20): 4/4 đạt, commit `f66f3be`.
- Unit/widget: `test/vietqr_bank_repository_test.dart` kiểm tra cache seed, dữ liệu JSON/API, refresh lỗi không xóa cache, loại bỏ BIN sai, chọn ngân hàng từ danh sách.
- **Chưa khẳng định** CI commit Bước 20 đạt hoặc migration v2→v3 đã chạy trên dữ liệu Redmi thật cho đến khi có kết quả kiểm chứng.

**Bước tiếp theo:** 21 (đề xuất LED toàn màn hình), chỉ sau khi xác minh CI và lệnh tiếp tục.
