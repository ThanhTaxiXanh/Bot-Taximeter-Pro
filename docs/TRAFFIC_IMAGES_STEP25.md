# Bước 25 — đối chiếu 7 ảnh giao diện và nguồn dữ liệu giao thông

**Ngày đọc nguồn: 20/11/2026.** Tài liệu đối chiếu trực tiếp từ 7 ảnh `IMG_4488.jpeg`–`IMG_4494.jpeg`, `MASTER PROMPT.md`, `traffic_signs.csv`, `speed_limit_signs.csv` và 2 bản GeoJSON cùng tên do người dùng đính kèm trong nguồn dự án ChatGPT. Những tệp gốc dung lượng lớn đang ở nguồn ChatGPT; **chưa sao chép dữ liệu biển báo vào ứng dụng** ở bước giao diện này.

## 1. Mô tả giao diện theo ảnh gốc

| Ảnh | Nội dung xác định từ nguồn |
|---|---|
| `IMG_4488.jpeg` | Home: bản đồ 3D chiếm phần lớn màn hình; mũi tên GPS xanh, **nhãn đường bo góc màu xanh đậm ngay dưới xe**, khối tốc độ và biển tròn 60, điều khiển 3D/2D/định vị/ngày-đêm/giao thông; nút Bắt đầu/Lịch sử |
| `IMG_4489.jpeg` | Tìm kiếm: thanh địa chỉ, danh sách điểm đến và từ khóa gần đây |
| `IMG_4490.jpeg` | Lập tuyến: điểm đi/dừng/đến, 3 tuyến, khoảng cách/ETA, bản đồ chỉ đường |
| `IMG_4491.jpeg` | Đang chạy: bản đồ 3D kèm tuyến xanh, **marker xe và pill tên đường dưới xe**, cước, quãng đường, thời gian chờ, nút Tạm dừng/Kết thúc/SOS |
| `IMG_4492.jpeg` | Doanh thu/lịch sử: biểu đồ, danh sách cuốc, thẻ bản đồ thu nhỏ |
| `IMG_4493.jpeg` | Chi tiết cuốc: bản đồ thu nhỏ, biên lai, VietQR và xuất PDF |
| `IMG_4494.jpeg` | Cài đặt: tilt 15°–80°, các nút Google Maps 2D/3D, lớp giao thông và hiển thị tên đường |

Đây là **ảnh thiết kế**, không phải bằng chứng bản đồ, địa điểm hoặc tên đường trong ảnh đã được GPS trên điện thoại xác minh.

## 2. Thực hiện giao diện trong Bước 25

- **Home:** `mapHeight = (screenHeight * .38).clamp(235,365)` thay cho `.32/.clamp(205,310)`. Ví dụ màn cao 940 logical px: bản đồ khoảng **357 px thay vì 301 px**, tăng 56 px (~18,6%). Phần nội dung còn lại vẫn cuộn được.
- **Đang chạy chuyến:** `TripMapPanel` tăng `218 → 270 px`, chiều cao khung nút `203 → 255 px` để không bó cụm điều khiển.
- **Tên đường dưới GPS:** `GpsMarkerArt` vẽ một BitmapDescriptor có mũi tên và pill đường ngay phía dưới, buộc cùng tọa độ `gps-vehicle` trong `SharedMapView`. Nhãn giữ ngang ở chế độ 3D vì marker không `flat`; không dùng API Google mới, Map ID, Places, Directions, Static Maps hoặc Google Geocoding.
- `roadName` truyền từ `GpsTracker.instance.roadName` trên **Home và Đang chạy**. Tên đường chỉ xuất hiện khi có **fix GPS được chấp nhận**; nếu không có fix sẽ không có marker. Nếu GPS có fix nhưng chưa có tên, nhãn ghi **“Chưa xác định tên đường”**, không dùng tên đường mẫu trong ảnh.
- Tên đường hiện được tra **theo thao tác chạm vào thẻ tên đường**, bằng `NominatimGeocodingProvider` khi người vận hành đã cấu hình máy chủ HTTPS được phép. Tính năng geocoding mặc định tắt; không truy vấn Nominatim công cộng, không tự động gửi GPS vào mạng khi bật app. Khi đi xa hơn 75 m từ điểm đã tra, tên cũ bị xóa.
- Tên quá dài bị rút gọn trên 44 Unicode codepoint; bỏ ký tự điều khiển, giữ dấu tiếng Việt. Thử trong `test/gps_marker_art_test.dart`; widget test dùng Canvas thay vì GoogleMap SDK.

## 3. Kiểm kê bốn tệp giao thông từ người dùng

| Tệp | Bản ghi | Trường dữ liệu |
|---|---:|---|
| `traffic_signs.csv` | **151.228** | `sign_id, longitude, latitude, sign_type_code, direction_raw, value_raw, meta_raw, tile_lat, tile_lon` |
| `traffic_signs.geojson` | **151.228 Feature/Point** | `sign_id, sign_type_code, direction_raw, value_raw` và tọa độ |
| `speed_limit_signs.csv` | **38.757** | `sign_id, longitude, latitude, speed_kmh_inferred, direction_raw, sign_type_code` |
| `speed_limit_signs.geojson` | **38.757 Feature/Point** | Các thuộc tính tốc độ và tọa độ tương ứng |

Hai bộ CSV/GeoJSON biểu diễn các tập dữ liệu tương ứng, **không phải bốn tập biển báo độc lập**. Trong bộ giới hạn tốc độ, `sign_type_code` đều bằng `1`; `direction_raw=255` xuất hiện **14.725/38.757 (38,0%)**. Ở bộ tổng hợp, `direction_raw=255` là **34.286/151.228 (22,7%)**. Nguồn **không cung cấp** bảng ý nghĩa các mã/độ chính xác hướng, nguồn xuất bản, thời điểm thu thập/cập nhật, chất lượng tọa độ hay quyền sử dụng lại dữ liệu.

Trong vùng lân cận tọa độ bản đồ mẫu Bắc Giang `(21.2741, 106.1946)`, bán kính **hình vuông ±0,02 độ** có **19 bản ghi** giới hạn tốc độ suy ra, với các giá trị khác nhau 40, 50, 60, 70, 80, 100 km/h. **Không có căn cứ lấy giá trị gần nhất làm giới hạn cho đúng làn đường/hướng xe.**

**Quyết định an toàn của Bước 25:** Chỉ sử dụng nguồn này để lập kiểm kê/đặt kế hoạch tích hợp. **Không import các tệp thô vào runtime, không vẽ biển suy đoán như biển thực tế, không tự ghi đè `SpeedLimitEngine`, không thay cảnh báo hoặc cước.** Lớp `trafficEnabled` hiện tại là lớp lưu lượng giao thông bản địa từ Maps SDK, **không phải** cơ sở dữ liệu biển báo vừa đính kèm.

## 4. Đề xuất bước kiểm chứng dữ liệu biển báo tiếp theo

1. Xác minh **nguồn phát hành, license, ngày cập nhật, bảng mã `sign_type_code`, `direction_raw`, `meta_raw`**, độ chính xác và điều kiện dùng thương mại. Nếu chưa biết, luôn ghi `chưa xác minh`.
2. Xây dựng parser Dart + test dữ liệu không hợp lệ, xử lý lặp/bản ghi lỗi, phân chia dữ liệu thành các vùng/tile có cache để không nạp 150 nghìn marker vào GoogleMap.
3. Khi người dùng bật lớp biển báo tham khảo, chỉ hiển thị theo viewport/zoom và số lượng marker được giới hạn. Luôn ghi `DỮ LIỆU THAM KHẢO — CHƯA XÁC MINH`, không tự dùng để cảnh báo vượt tốc độ.
4. Chỉ dùng `SpeedLimitEngine` cho giới hạn giao thông sau khi đã xác minh biển áp dụng đúng chiều, loại xe, phạm vi biển bắt đầu/kết thúc, và hiệu lực văn bản. **Biển thực tế trên đường luôn được ưu tiên.**

## 5. Cần thử trên điện thoại

- [ ] Cài **đè** APK sau khi CI cho đúng commit Bước 25 báo **4/4**, không xóa dữ liệu lịch sử.
- [ ] Home: so kích thước bản đồ với ảnh `IMG_4488` trên Redmi; phóng/thu, 2D/3D, traffic, Follow không che nút chính; màn nhỏ vẫn cuộn được.
- [ ] Đang chạy: bản đồ cao hơn, chữ cước và nút Tạm dừng/Kết thúc/SOS vẫn trong vùng cuộn, không tràn.
- [ ] Có GPS thật: mũi tên xuất hiện đúng tọa độ; pill **nằm dưới marker**, đi theo xe trên 2D/3D, **không xoay chữ** khi thay góc camera.
- [ ] Chưa có tên đường: hiện `Chưa xác định tên đường`; khi chạm thẻ tra cứu và máy chủ Nominatim hợp lệ trả tên, pill đổi sang tên thật. Nếu chưa có endpoint, giữ trạng thái chưa xác định; không dùng `Đường Trần Nhân Vũ` mẫu để khẳng định GPS.
- [ ] Khi mất fix, cả mũi tên và nhãn bị ẩn; tên cũ không được dùng làm giới hạn tốc độ.
- [ ] Bật/tắt traffic chỉ dùng tính năng của Maps SDK. Kiểm tra không tạo chi phí Google ngoài dự kiến; nghiệm thu thực địa/GPS/chi phí **chưa được xác nhận**.

**CI trước bước:** #44 commit `ae9f75b` đạt 4/4. **CI của commit Bước 25 phải được xác minh sau khi push.** Bước sau đề xuất: 26 — tích hợp biển báo tham khảo có kiểm định nguồn và test an toàn, theo yêu cầu tiếp theo.
