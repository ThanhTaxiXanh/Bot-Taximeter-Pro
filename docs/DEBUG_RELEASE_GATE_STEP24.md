# BỘT TAXIMETER PRO — Bước 24: cổng bàn giao bản debug

**Lập ngày 20/11/2026.** Đây là bước **bổ sung sau lộ trình 14 mục** của `MASTER PROMPT.md`, nhằm khóa các ràng buộc an toàn khi bàn giao bản APK debug cho điện thoại cá nhân. **Không phải chứng nhận đồng hồ taxi, phát hành Play Store hay nghiệm thu thực địa.**

## 1. Bản chuẩn đã xác minh trước bước 24

| Bằng chứng | Giá trị đã xác minh |
|---|---|
| Branch `main` | Commit `c473bb4d57ecb14de85f62362af81b059914ef48` |
| CI | [#43](https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/actions/runs/44708796825), 4/4 theo [Issue #1](https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/issues/1) |
| Flutter | 3.50.1 stable |
| APK | [Release `debug-latest`](https://github.com/ThanhTaxiXanh/Bot-Taximeter-Pro/releases/tag/debug-latest), tại thời điểm lập: build #43, target `c473bb4` |
| Tên file | `BOT-TaxiMeterPro-debug.apk` (build debug arm64) |
| Package thực tế | `vn.bottaximeter.bot_taximeter_pro` |
| SHA-1 debug | `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4` |
| Nghiệm thu trên Redmi | **CHƯA XÁC NHẬN**; xem `docs/ACCEPTANCE_STEP23.md` |

**CI của commit Bước 24 chưa được xác nhận tại thời điểm soạn.** Luôn đối chiếu SHA trong Release với Issue #1 sau mỗi lần đẩy mã; release `debug-latest` có thể thay đổi.

## 2. Cổng kiểm thử hồi quy Bước 24

`test/release_guardrails_test.dart` chạy trong `flutter test`; kiểm tra trực tiếp mã nguồn và giá trị runtime:

1. Application ID cố định và **7 route GoRouter** không bị thêm/sửa ngoài ý muốn.
2. `SharedMapView` còn dùng native Maps SDK, style JSON và traffic SDK, **không có tham số `mapId`/`cloudMapId`**; `pubspec.yaml` giữ dependency `google_maps_flutter` ghim phiên bản và không thêm một số SDK Google paid thường gặp.
3. Trong widget test/CI, GPS/Maps vẫn dùng mock; **GPS trong chuyến = 1 giây / 0 m**, GPS Home = 5 giây / 10 m.
4. Đúng quy tắc `roundVnd` (dư đúng 500 làm tròn xuống, 501 làm tròn lên), phí chờ và BOT sau làm tròn.

Đây là **rào chắn mã nguồn**, **không phải đo hóa đơn Google** hoặc khẳng định không có bất kỳ request trả phí nào. Kiểm toán chi phí thực tế cần xem Google Cloud Billing theo SKU; giá và điều khoản có thể thay đổi.

## 3. Quy tắc sử dụng debug-latest an toàn

- Chỉ cài khi **báo cáo Issue #1 của đúng commit bản APK đạt 4/4**. Workflow `success` riêng lẻ không đủ bằng chứng vì từng có test `continue-on-error`.
- Cài đè APK đúng package và chữ ký; không gỡ app, xóa dữ liệu hay `Clear storage` nếu muốn giữ các cuốc đã lưu. Trước cập nhật, ghi lại số cuốc và tổng tiền trong màn Lịch sử.
- APK là **debug** ký bằng khóa trong repo cho kiểm thử cá nhân. **Không dùng làm bản phát hành sản phẩm đại trà**, không coi keystore debug là khóa phát hành bí mật, và không công bố khóa Google Maps. Bản thương mại nếu có sẽ cần quy trình ký và tuân thủ riêng.
- Không lái xe đồng thời thử nút. Không đặt mã PIN/OTP, khóa API, thông tin ngân hàng cá nhân hay tọa độ riêng vào ảnh báo lỗi.
- Không dùng ứng dụng làm đồng hồ tính cước pháp lý; GPS, biển báo, ETA và cước là giá trị hỗ trợ/tham khảo.

## 4. Kiểm tra nhanh 10–15 phút trên Redmi khi xe đang đỗ

- [ ] **Cài đè:** lịch sử chuyến và biểu phí cũ vẫn còn, màn Home mở được; xem Google Maps thật nếu key hợp lệ.
- [ ] **GPS Home:** bật thủ công, có marker khi fix hợp lệ; chuyển app ra nền và trở lại thì GPS xem trước dừng đúng thiết kế.
- [ ] **Chuyến thử:** bật GPS khi được hỏi, thông báo theo dõi nền hiện; đưa app ra nền ngắn rồi trở lại, chuyến không tự kết thúc. Có thể tạo chuyến không di chuyển khi xe đang đỗ.
- [ ] **Waiting/BOT:** tạm dừng, kiểm tra thời gian chờ; tiếp tục, cộng BOT mẫu, kết thúc và xác nhận. Cước không tự nhảy quãng đường khi GPS yếu.
- [ ] **Lịch sử/PDF:** chuyến vừa hoàn thành có đúng tổng tiền và biên lai; PDF tiếng Việt có dấu và cảnh báo `chưa kiểm định`.
- [ ] **VietQR:** bật tùy chọn nếu thật sự cần, xem dữ liệu ngân hàng offline; xác minh BIN/số tài khoản với ứng dụng ngân hàng trước khi cho khách quét; QR không báo đã nhận tiền.
- [ ] **SOS/LED:** SOS không tự gọi/gửi; LED mở bằng câu chào từ Cài đặt, đóng được, không tự lưu.
- [ ] **Google Cloud:** key giới hạn Android package/SHA-1 đúng, chỉ bật Maps SDK Android theo mục đích; kiểm tra Billing Reports và Budget Alerts, nhớ rằng **Budget Alerts không tự dừng phí**.

Checklist đầy đủ và các mục khó kiểm thử hơn (migration với dữ liệu cũ, khôi phục, Android khóa màn hình, tốc độ, lọc nhiễu, geocoding) tại [`docs/ACCEPTANCE_STEP23.md`](ACCEPTANCE_STEP23.md).

## 5. Phân loại kết quả nghiệm thu

| Trạng thái | Tiêu chí |
|---|---|
| **CI đạt** | Issue #1 xác nhận analyze, test, APK, UI Android 13 đều đạt đúng SHA |
| **Có thể thử trên máy cá nhân** | CI đạt và APK cùng SHA; tài xế đã có bản sao/thông tin lịch sử để đối chiếu |
| **Nghiệm thu thực địa** | Tài xế xác nhận checklist thiết bị, GPS nền, cước, dữ liệu cũ, Google Maps/Cloud, VietQR/PDF/SOS/LED |
| **Chưa cho phép khẳng định** | Đồng hồ cước kiểm định, thanh toán đã thành công, an toàn GPS mọi máy Android, hóa đơn Google bằng 0 hoặc phát hành thương mại |

**Chưa có dữ liệu thử nghiệm trên Redmi trong cuộc hội thoại này.** Các ô thiết bị giữ chưa đánh dấu. Khi báo lỗi, gửi tên màn hình, thao tác, kết quả thực tế/mong đợi và bản CI; tránh mọi dữ liệu nhạy cảm.

**Việc tiếp theo đề xuất (Bước 25):** Chỉ xử lý các phát hiện đã có bằng chứng từ CI hoặc quá trình thử thực địa. Không tự thêm tính năng khi chưa có lỗi/yêu cầu mới.
