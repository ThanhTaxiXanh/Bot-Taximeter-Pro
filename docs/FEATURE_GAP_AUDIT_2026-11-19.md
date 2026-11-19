# BỘT TAXIMETER PRO — BƯỚC 16: KIỂM TOÁN KHOẢNG TRỐNG CHỨC NĂNG

- Ngày đối chiếu: **19/11/2026**.
- Nguồn yêu cầu: **MASTER PROMPT.md** đã được người dùng đưa vào Project ChatGPT (970 dòng; mục 3–10), chưa tìm thấy file tương ứng trong thư mục gốc repo `main` lúc rà soát.
- Nguồn hiện trạng: mã nguồn và tài liệu `ThanhTaxiXanh/Bot-Taximeter-Pro` tại commit `712dff98cf7dac8f2d8041a3288330df1596ab1d`, `PROGRESS.md`, báo cáo Issue #1 và CI #30.
- Nghiệm thu thực địa: người dùng báo **5/5** mục đạt trên Redmi Note 12 Pro; quét VietQR đúng người nhận/số tiền **không chuyển khoản**. Đây là xác nhận từ người dùng, không phải log thiết bị độc lập.
- Mốc CI ứng dụng: #30, `2ec236ba1a6effdcea8321f8c536a04a178af6fd`; analyzer đạt, 66/66 unit/widget, APK arm64, Android 13 9/9.

## A. Nguyên tắc đối chiếu

1. Lộ trình Master Prompt **mục 10 chỉ có Bước 1–14**, không quy định Bước 15/16. Bước 13 gốc bao gồm SQLite, thống kê, VietQR, ngân hàng và PDF; quá trình triển khai đã tách thành Bước 13–15. Đây là **Bước 16 kiểm toán tài liệu**, không phải một bước tính năng được Master Prompt đặt tên.
2. Chỉ kết luận **thiếu** khi mã hiện có cho thấy rõ tính năng mẫu/chưa kết nối, hoặc không có cấu trúc/dịch vụ/bài test tương ứng; phân biệt **chưa kiểm thử** với **chưa triển khai**.
3. Không đổi package Android `vn.bottaximeter.bot_taximeter_pro`, 7 route, theme, biểu phí, quy tắc làm tròn, ký debug, workflow CI, SQLite v1→v2 và luồng VietQR/PDF đã nghiệm thu.
4. Mọi nội dung cước GPS là **tham khảo, chưa được kiểm định**. Quét VietQR không xác nhận đã chuyển hay nhận tiền. Dữ liệu pháp luật về tốc độ phải được kiểm chứng theo văn bản có hiệu lực ở thời điểm triển khai.

## B. Ma trận khoảng trống xác minh theo Master Prompt

| ID | Ưu tiên | Master Prompt | Bằng chứng trong mã hiện tại | Kết luận và tiêu chí hoàn thành |
|---|---|---|---|---|
| G01 | **P0** | Mục 6B, Bước 12 gốc: `speed_rules.dart`, `SpeedLimitEngine`, `RoadContextProvider`, quy tắc pháp lý, biển và tốc độ tối thiểu, ghi đè và cảnh báo theo bậc | `lib/features/road_safety/speed_alert_engine.dart` chỉ kiểm tra **ngưỡng cá nhân**; `home_page.dart` ghi rõ `Giới hạn tốc độ (minh họa)`; `trip_page.dart` ghi `Biển giới hạn vẫn là dữ liệu mẫu`; chưa có thư mục `features/speed_limit` hoặc test `speed_limit_rules_test.dart` | **Thiếu phần cốt lõi của Bước 12 gốc**. Xây dựng mô hình pháp lý từ nguồn chính thức đã xác minh, ưu tiên manual→posted→rule→unknown; không có ngữ cảnh thì `--`, không báo vượt. Sau đó mới tích hợp UI, Overpass/cache, cảnh báo theo bậc |
| G02 | **P0** | Mục 8, Bước 14 gốc: SOS xác nhận→gọi số cấu hình→chia sẻ vị trí bằng `url_launcher`/`share_plus` | `lib/features/trip/presentation/trip_page.dart` `_sos()` hiện hộp thoại `SOS (bản mẫu)` và thông báo **chưa gọi điện hoặc gửi vị trí**; `pubspec.yaml` chưa có các dependency tương ứng | **Thiếu chức năng SOS thật**. Sau xác nhận, mở trình gọi điện, chủ động chia sẻ GPS được cấp quyền; xử lý khi không có GPS/ứng dụng phù hợp, không tự gọi/gửi |
| G03 | **P1** | Mục 6 và Bước 11 gốc: OSRM turn-by-turn trong chuyến, khoảng cách còn đến rẽ và tính lại tuyến khi lệch >50 m | `route_live_panel.dart` hiển thị tuyến OSRM, ETA, tối đa 12 bước rẽ **trước chuyến**; `route_page.dart` nút bắt đầu chỉ điều hướng sang `TripPage`; `trip_page.dart` ghi `Tuyến, biển tốc độ và chỉ dẫn rẽ vẫn là mẫu` | **Thiếu dẫn đường GPS theo thời gian thực**; giữ riêng khoảng cách tuyến để không can thiệp cước GPS |
| G04 | **P1** | Mục 8/Bước 13 gốc: tải danh sách ngân hàng/BIN VietQR, seed JSON offline và cache bảng `banks` trong SQLite | `settings_page.dart` cho nhập thủ công BIN/tên/tài khoản; `taximeter_database.dart` chỉ tạo `trip_snapshots`, `completed_trips`; không có JSON seed ngân hàng trong `assets/` | **Thiếu danh mục và cache ngân hàng**. Bổ sung nguồn dữ liệu hợp lệ, seed offline, migration không phá hủy và unit/integration test; kiểm chứng BIN/thời hạn cache |
| G05 | **P1** | Mục 8/Bước 14 gốc: Câu chào LED toàn màn hình | `settings_page.dart` có trường `Câu chào LED` và lưu `led_greeting`; cây mã chưa có màn hình/route hiển thị LED toàn màn hình | **Mới có cấu hình**, thiếu chế độ trình chiếu full-screen, mở/đóng và kiểm thử |
| G06 | **P1** | Mục 8/Bước 13 gốc: bảng `trips` giàu dữ liệu (điểm đón/trả, tọa độ, polyline, chi tiết cước, phương thức thanh toán, khách tùy chọn) | `taximeter_database.dart` bảng `completed_trips` chỉ gồm 8 trường cước/thời gian; `completed_trip.dart` không chứa pickup/drop, polyline, payment status và customer tùy chọn | **Lịch sử cơ sở đã hoàn thành, dữ liệu chi tiết còn thiếu**. Đề xuất schema v3/migration bổ sung, backfill `NULL` cho dữ liệu cũ, không xóa DB/snapshot |
| G07 | **P2** | Mục 5/Màn 2: tìm kiếm bằng giọng nói tiếng Việt (`speech_to_text`) ở bước sau | `pubspec.yaml` không có `speech_to_text`; `search_page.dart` và `search_live_panel.dart` có tìm kiếm gõ chữ/máy chủ | **Chưa tích hợp nhận dạng giọng nói**; chỉ thêm khi có cơ chế xin quyền micro và xử lý offline/không hỗ trợ |
| G08 | **P2** | Mục 5/Màn 3: `Lưu tuyến`, so sánh ít phí/ít kẹt xe | `route_page.dart` nút `Lưu tuyến` báo `Chức năng lưu tuyến sẽ có ở bước sau`; các chip lựa chọn và ba tuyến demo vẫn tồn tại | **Nút lưu tuyến chưa hoạt động**; chưa chứng minh tiêu chí chọn tuyến ít phí/ít kẹt xe dựa dữ liệu thật |
| G09 | **P2** | Mục 5/Màn 5: thống kê/so sánh hôm qua, cuốc chi tiết và thanh toán | `history_page.dart` tính số cuốc, tổng cước GPS, km, thời gian, biểu đồ 7 ngày; chưa có phép đối chiếu hôm qua, còn thiếu trường dữ liệu của G06 | **Còn thiếu so sánh biến động**; không gắn nhãn doanh thu thực nhận khi chưa có đối soát thanh toán |
| G10 | **P2** | Mục 6 và Bước 14 gốc: cảnh báo kẹt xe heuristic; âm báo/rung tốc độ, cảnh báo theo nguồn đúng | `settings_page.dart` có công tắc `Cảnh báo kẹt xe`, `Âm báo tốc độ`, `Rung cảnh báo`; `trip_page.dart` chưa có engine theo dõi kẹt xe, chỉ dẫn mock; `road_safety` mới xử lý ngưỡng cá nhân | **Chưa chứng minh được cảnh báo giao thông hoạt động thật**; cần bổ sung cơ chế an toàn, không suy diễn từ lớp traffic của Maps |
| G11 | **P2** | Mục 3, Bước 14 gốc: tối ưu pin, kiểm soát phí Google, README hoàn thiện | `GpsTracker` có foreground notification/wakelock; `trip_page.dart` có nút hướng dẫn pin; `docs/GOOGLE_MAPS_SETUP.md` có hướng dẫn hạn chế API; `README.md` hiện chỉ có tiêu đề đơn giản | **Tối ưu pin mới có phần cơ sở**; cần kiểm chứng dịch vụ nền kéo dài, kiểm toán cấu hình/billing/quota Google thực tế và tài liệu README hoàn chỉnh. Không thể xác nhận chi phí 0 từ mã |
| G12 | **Kiểm thử thêm** | Bước 11 gốc: Nominatim/OSRM và reverse geocode thật được phép | `docs/ROUTING_SETUP.md` yêu cầu máy chủ HTTPS được phép, tính năng mặc định tắt; báo cáo 5/5 Redmi chưa xác nhận đã thử tìm địa chỉ/tuyến thật với máy chủ này | **Chưa được xác minh thực địa**, không mặc nhiên coi mã dịch vụ là lỗi; thử riêng với máy chủ được phép |

## C. Phần đã có, không xây lại

- GPS được lọc, distance Haversine, foreground theo quyền và snapshot/khôi phục SQLite hiện tại.
- FareCalculator: 30.000đ/1,5 km; các bậc 13.000/11.500/10.000 đ/km, phí chờ, BOT cộng sau làm tròn; 500đ làm tròn xuống.
- `completed_trips` và thống kê cơ sở; biên lai PDF tiếng Việt offline; payload VietQR offline và QR chỉ tạo sau thao tác chủ động.
- Google Maps SDK Android qua `SharedMapView` với Map style JSON, 2D/3D và giao thông; phần tìm địa chỉ và tuyến OSRM/Nominatim theo máy chủ được phép.
- Người dùng đã báo 5/5 mục nghiệm thu Redmi đạt; CI #30 đã đạt 4/4. **Không suy ra được tính hợp pháp của đồng hồ cước hay tiền đã về ngân hàng**.

## D. Thứ tự khuyến nghị cho các lượt triển khai sau

| Lượt dự kiến | Phạm vi giới hạn một lượt | Điều kiện nghiệm thu |
|---|---|---|
| **Bước 17 (đề xuất)** | Nền tảng quy tắc giới hạn tốc độ pháp lý: `LegalBasis`, `RoadContext`, các bảng `speed_rules.dart`, engine và unit test. **Chưa kích hoạt báo giới hạn pháp lý** khi nguồn chưa đủ | Xác minh văn bản quy phạm còn hiệu lực, kiểm thử tổ hợp loại xe/khu vực/kiểu đường, nguồn unknown không cảnh báo; không sửa hệ thống ngưỡng cá nhân cũ |
| Bước 18 (đề xuất) | Tích hợp tốc độ vào UI, ghi đè/ghi nhớ theo đoạn, road context/OSM cache, cảnh báo theo bậc | Không dùng dữ liệu suy đoán làm biển báo hợp pháp; test/CI và kiểm thử an toàn trên thiết bị |
| Bước 19 (đề xuất) | SOS thật qua xác nhận người dùng | Test dialog, xử lý lỗi thiếu quyền, không gọi điện hoặc chia sẻ tự động |
| Bước 20 (đề xuất) | Danh sách ngân hàng VietQR, cache/seed SQLite | Migration an toàn, QR hiện hữu không đổi; test BIN và offline |
| Bước 21 (đề xuất) | Dẫn đường GPS theo tuyến OSRM có phép, cảnh báo lệch tuyến | Không ảnh hưởng tiền cước; không gọi máy chủ công cộng bị hạn chế |
| Bước 22+ (đề xuất) | LED toàn màn hình, lịch sử chi tiết, giọng nói, lưu tuyến, thống kê/cảnh báo, tài liệu và audit chi phí | Tách từng bước nhỏ, có unit/widget/integration test, tối đa khoảng 5 file Dart/lượt |

## E. Quy tắc thực hiện tiếp

- **Bước 16 chỉ kiểm toán và ghi tài liệu**, không sửa mã ứng dụng, không thay đổi CI/package/SQLite/theme, không tự xây lại từ đầu.
- Đọc `PROGRESS.md`, audit này, CI hiện hành, file liên quan trước mỗi lượt; ghim dependencies; mỗi bước một commit và cập nhật tiến độ; dừng chờ `TIẾP TỤC`.
- Master Prompt phần giới hạn khóa Android có ví dụ package `vn.bottaximeter.pro` khác package của APK đã nghiệm thu: **giữ package thực tế `vn.bottaximeter.bot_taximeter_pro`**, đối chiếu cùng SHA-1 debug CI khi cấu hình Maps.
- Để Master Prompt thành nguồn chung trên GitHub, người dùng có thể bổ sung bản gốc vào repo; không tự sao chép tài liệu Project vào repo khi chưa cần thiết.
