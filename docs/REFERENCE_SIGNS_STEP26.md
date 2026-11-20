# Bước 26 — Lớp biển giới hạn tốc độ THAM KHẢO (Bắc Giang)

**Ngày 20/11/2026.** Dựa trực tiếp trên dữ liệu người dùng tại nguồn dự án ChatGPT: `speed_limit_signs.csv`, `traffic_signs.csv`, 2 GeoJSON tương ứng và tài liệu [Bước 25](TRAFFIC_IMAGES_STEP25.md). Không dùng kiến thức tổng quát thay cho mã/giá trị gốc trong dữ liệu.

## Nguồn và phạm vi trích xuất

- Nguồn gốc: `speed_limit_signs.csv`, **38.757 dòng**, cột `sign_id,longitude,latitude,speed_kmh_inferred,direction_raw,sign_type_code`. Cột `speed_kmh_inferred` là **giá trị suy ra**, không phải biên bản xác nhận giới hạn có hiệu lực.
- **Bản thử nghiệm thực sự tích hợp:** 147 dòng thỏa **`|latitude − 21.2741| <= 0.075` và `|longitude − 106.1946| <= 0.075`**, quanh điểm demo Bắc Giang. Không phải dữ liệu toàn tỉnh, không phải 38.757 biển trên toàn Việt Nam.
- Mỗi dòng giữ `sign_id`, tọa độ làm tròn về 6 chữ số thập phân như CSV, `speed_kmh_inferred` và **`direction_raw` chưa giải mã**. Bảng dữ liệu được nén gzip/base64 trong `lib/features/map_tracking/data/reference_speed_signs.dart`, chỉ giải mã khi bật chế độ. Bản trích xuất 147 dòng có SHA-256 (CSV nội bộ 5 cột `id,lat_e6,lon_e6,speed,direction`): `d45fab7f18d91d4557373cc01a9763587de86948990a8e3ba3e41ad210c22624`.
- Trong mẫu có **47/147 bản ghi `direction_raw=255`**. Không có bảng mã chính thức giải thích `direction_raw`, `sign_type_code`, thời gian cập nhật, sai số định vị hoặc giấy phép phân phối. Khi sử dụng nguồn cho mục đích phân phối/thương mại phải **xác minh quyền sử dụng** trước; repo hiện chỉ gồm bộ thử nghiệm nhỏ.
- `traffic_signs.csv` với **151.228 dòng** và `traffic_signs.geojson` **không được nhúng vào APK** ở bước này vì chưa có bảng ý nghĩa biển đầy đủ và kiểm định nguồn. Chỉ `sign_type_code=1` thuộc bộ `speed_limit_signs.csv` được thử để hiển thị riêng.

## Cách dùng giao diện

1. Mở **Home**, quan sát bản đồ lớn từ Bước 25. Nhấn nút **Biển tham khảo** ở góc trái bên dưới khối tốc độ để bật lớp; mặc định luôn tắt khi mở Home.
2. Khi bật, `ReferenceSpeedSigns` tìm các điểm trong **1.600 m** quanh GPS đã lọc; nếu chưa có GPS, dùng **tâm demo Bắc Giang** và vẫn phải coi đây là vị trí minh họa. Không có nguồn biển trong vùng thì không có ghim, **không suy ra giới hạn bằng 0 hay giới hạn theo vùng khác**.
3. Dữ liệu đi qua kiểm tra dạng số/giá trị hợp lệ, loại ID trùng, loại tọa độ ngoài phạm vi, chọn theo khoảng cách; gộp các ghim gần nhau theo ô khoảng 40 m; hiển thị **tối đa 16 ghim màu cam**. Không sinh 147 marker cùng lúc và không dùng Google API bổ sung.
4. Chạm ghim cam: popup **“Suy ra ~N km/h · CHƯA XÁC MINH”** cùng ID và mã hướng thô. Ghim cam khác với marker GPS xanh và nhãn tên đường bên dưới xe.
5. Tắt nút để ẩn toàn bộ biển tham khảo; lớp **traffic** của Google Maps vẫn là lớp giao thông riêng.

## Giới hạn an toàn và kỹ thuật

- **Không tích hợp** các giá trị suy ra vào `SpeedLimitEngine`, `SpeedAlertController`, biển đang hiển thị tốc độ chính, logic tính cước hoặc định tuyến. **Không sử dụng các ghim để xác định giới hạn hợp pháp hay tránh xử phạt**. Tài xế cần ưu tiên biển thực tế và quy định.
- Bật/tắt chỉ theo thao tác người dùng; không gửi tọa độ đến máy chủ, không gọi Places, Routes, Directions, Maps Tiles hoặc Map ID có phí; chỉ dùng `google_maps_flutter` Android hiện có.
- Đây là *bản pilot vùng Bắc Giang*: di chuyển ra khỏi phạm vi trích xuất sẽ không hiện ghim, chứ không khẳng định ngoài vùng không có biển thật. Các ghim đang tính quanh GPS/tâm demo, **chưa tự thay đổi theo viewport khi người dùng kéo bản đồ**.
- Widget test trên CI vẫn hiển thị Canvas, không tải GoogleMap native và không kiểm tra vị trí chính xác biển. Các test mới: `test/reference_speed_signs_test.dart` (parser, duplicate, limit, phạm vi/định dạng) và `test/home_page_test.dart` (nút mặc định tắt/bật).
- **CI trước bước:** #45, commit `6934852`, đạt 4/4. **CI sau commit Bước 26 chưa xác nhận tại thời điểm ghi.** Không đổi cước, GPS, SQLite, SOS, VietQR, PDF, LED, 7 route, workflow hay khóa ký.

## Chưa nghiệm thu trên điện thoại

- [ ] Sau CI Bước 26 đạt đúng SHA, tải và **cài đè APK**, giữ dữ liệu lịch sử.
- [ ] Khi xe đỗ tại Bắc Giang, mở Home, bật **Biển tham khảo** rồi kiểm tra các ghim cam xuất hiện nếu có điểm trong bán kính 1,6 km quanh vị trí đã xác định.
- [ ] Chạm ghim, kiểm tra popup `CHƯA XÁC MINH`; tắt lớp thì không còn ghim, không ảnh hưởng marker GPS hoặc tên đường.
- [ ] Kiểm tra góc màn hình nhỏ không che 2D/3D, nút Bắt đầu, Lịch sử; tắt/bật lớp traffic Google Maps độc lập.
- [ ] Đối chiếu tại chỗ: mã hướng, chiều/làn, loại xe, giới hạn bắt đầu/kết thúc, hiệu lực biển và nguồn xuất bản; **không coi ghim dữ liệu là căn cứ chạy xe**.

**Bước sau đề xuất:** sau CI đạt, xác minh giấy phép/nguồn của dữ liệu và xây nạp theo viewport/tile cho phạm vi rộng hơn, không tự bật cảnh báo tốc độ.
