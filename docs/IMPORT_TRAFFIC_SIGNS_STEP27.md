# Bước 27 — Nhập đầy đủ dữ liệu biển báo của người dùng trên Android

**Ngày 20/11/2026.** User đã xác nhận cả hai CSV và hai GeoJSON là **dữ liệu do chính mình thu thập**, cho phép đưa vào bản đồ. Đây là lớp biển báo từ dữ liệu cá nhân, không phải nguồn giới hạn tốc độ có hiệu lực được cơ quan quản lý xác nhận. Không tự động sử dụng để ra cảnh báo vượt tốc độ.

## 1. Tệp gốc và khả năng nhập

| Tệp từ nguồn dự án ChatGPT | Số bản ghi gốc | Cách sử dụng |
|---|---:|---|
| `traffic_signs.csv` | **151.228** | **Khuyên dùng**: mọi loại biển thu thập (cột ID, longitude, latitude, sign_type_code, direction_raw, value_raw, meta_raw và tile) |
| `speed_limit_signs.csv` | **38.757** | Tùy chọn: chỉ những biển tốc độ được suy ra; giá trị tốc độ được giữ ở `raw_value` |
| `traffic_signs.geojson` | 151.228 | Cùng tập bản ghi với CSV; chưa có chức năng chọn GeoJSON trên Android |
| `speed_limit_signs.geojson` | 38.757 | Cùng tập với CSV tốc độ; chưa nhập GeoJSON |

**Nhập một CSV mỗi lần**; việc nhập mới thay thế bộ đã nhập trước đó, không gộp hai bộ để tránh nhân đôi biển. `traffic_signs.csv` bao gồm biển tốc độ; chọn tệp này nếu muốn xem đủ các loại biển. Hệ thống giữ nguyên các trường gốc có ý nghĩa đối với việc xem biển: `sign_id`, tọa độ, `sign_type_code`, `direction_raw`, `value_raw`, `meta_raw`. Trường tile được dùng trong dữ liệu nguồn, nhưng không lưu riêng vì ứng dụng sử dụng truy vấn SQLite theo tọa độ.

Không nhúng 7,2 MB CSV trực tiếp vào commit GitHub ở Bước 27: **người dùng nhập một lần bằng trình chọn tệp trên điện thoại**, sau đó dữ liệu nằm ngoại tuyến trong `imported_traffic_signs.db`. Bản debug vẫn có 147 biển mẫu Bắc Giang khi chưa nhập CSV. Có thể đưa toàn bộ nguồn vào bản đồ mà không cần gửi dữ liệu qua máy chủ.

## 2. Thao tác trên Redmi

1. Tải tệp `traffic_signs.csv` từ nguồn tệp ChatGPT về thư mục **Tải xuống / Downloads** trên điện thoại (giữ nguyên tên cột).
2. Cài đè APK debug **sau khi CI của đúng commit Bước 27 đạt 4/4**.
3. Home → nhấn **biểu tượng tệp có mũi tên** cạnh chip **Biển tham khảo** → chọn `traffic_signs.csv` từ bộ chọn tệp Android. Đợi thông báo `Đã lưu 151228 biển...` (nếu mọi bản ghi hợp lệ; trùng ID bị thay thế).
4. Ứng dụng tự bật lớp sau khi nhập. Trên chip sẽ hiện số lượng đã lưu `Biển: 151228`. Kéo/phóng bản đồ: các ghim màu cam trong vùng nhìn được tải từ SQLite, tối đa **32** ghim một lúc. Khi rời vùng Bắc Giang vẫn có dữ liệu từ CSV.
5. Chạm ghim cam: xem **loại biển, ID, tọa độ, mã hướng, giá trị và meta thô**; biển loại `1` có giá trị từ 5–120 hiển thị nhãn tốc độ. Tắt chip để ẩn ghim; bật lại không cần nhập lần nữa. Sau khởi động lại, bộ dữ liệu vẫn lưu trên máy.

Nếu chỉ tải `speed_limit_signs.csv`, làm tương tự, số bản ghi kỳ vọng **38.757**. Sau khi nạp bản tổng hợp `traffic_signs.csv`, không cần tiếp tục nạp bộ tốc độ, vì nó sẽ thay thế tập tổng hợp.

## 3. Cách triển khai

- Thêm `file_selector: 1.1.0` (plugin chính thức thuộc hệ sinh thái Flutter) để mở bộ chọn tệp Android qua trình chọn tệp của hệ thống, **không yêu cầu quyền đọc toàn bộ bộ nhớ**.
- `ImportedRoadSigns.importCsv(XFile)` đọc stream UTF-8 CSV, kiểm tra tên cột chính xác và giới hạn kích thước **18 MiB**; từ chối tọa độ sai, ID âm, mã loại âm và hướng ngoài 0–255. Ghi lô **600 bản ghi/đợt** trong **một transaction**; lỗi bất kỳ sẽ rollback, không mất tập cũ.
- Lưu SQLite **riêng** tại đường dẫn app-scoped `imported_traffic_signs.db`, không chỉnh `bot_taximeter.db`, version 3, biểu phí hoặc lịch sử. Tạo index `(lat,lon)`.
- `SharedMapView` báo `onViewportChanged` khi GoogleMap đã tạo hoặc camera dừng, `TrafficSignsControls` yêu cầu `markersInBounds` lọc theo khung địa lý. Truy vấn tối đa **800 ứng viên** gần tâm và gộp các ô phân bố đều trên màn hình, hiển thị **tối đa 32 marker**, không tạo 151 nghìn widget/marker.
- Đổi vùng nhìn chỉ khi người dùng kéo/zoom hoặc camera Follow thay đổi, không gọi API định tuyến, geocoding, Places, Dynamic Maps hay Map Tiles. Trường hướng và giá trị vẫn ở mức **dữ liệu thu thập**, không tự suy ra chiều/làn xe. Không sửa `SpeedLimitEngine`, `SpeedAlertController` hay tính cước.
- Trong CI/widget test không tự mở bộ chọn tệp hoặc SQLite Android. Bổ sung `test/imported_road_signs_test.dart`: parser các hàng đầu thực từ CSV, BOM, kiểm tra loại/hướng và trường thô; Android thực cần nghiệm thu nhập/hiển thị.

## 4. Giới hạn và kiểm tra trên điện thoại

- [ ] CI đúng commit Bước 27 đạt 4/4 (workflow `success` riêng lẻ không đủ).
- [ ] Nhập `traffic_signs.csv` trên Redmi, quan sát số lượng **151.228** sau import; nếu khác, xem thông báo/định dạng tệp. Thời gian import phụ thuộc phần cứng và dung lượng, không có ETA cứng.
- [ ] Bật, tắt, phóng/thu và kéo bản đồ cả Bắc Giang và khu vực khác; tối đa 32 ghim cam; nhãn tên đường nằm dưới marker GPS và không bị ảnh hưởng.
- [ ] Kiểm tra lúc không có mạng: biển đã nhập vẫn hiện; thoát/mở lại ứng dụng không mất tập biển.
- [ ] Kiểm tra cài đè APK không mất lịch sử, thu phí, snapshot hoặc dữ liệu đã nhập. Không gỡ/cài mới nếu muốn giữ dữ liệu.
- [ ] Kiểm chứng thực địa mỗi biển theo chiều đường, làn, loại xe và hiệu lực; không chạy xe dựa vào biển thu thập khi chưa đối chiếu.

**Nguồn dữ liệu từ tệp do người dùng cung cấp, không tự khẳng định số liệu là biển pháp lý hiện hành.** Bản nhúng 147 biển Bắc Giang vẫn là chế độ mẫu khi chưa có CSV nhập. **Chưa xác nhận nghiệm thu Android thật tại thời điểm code.**

**CI đầu vào:** #46, commit `4a5ff46`, đạt 4/4. **Bước tiếp theo:** 28 — sửa lỗi CI nếu có, sau đó nghiệm thu nhập 151.228 bản ghi thực tế và tối ưu độ phủ/viewport theo phản hồi Redmi.
