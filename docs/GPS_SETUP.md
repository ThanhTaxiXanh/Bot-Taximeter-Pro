# GPS thật và tên đường (Bước 9)

Bước này cho phép bật GPS thiết bị, hiển thị marker/tốc độ/độ chính xác thật trên Home, Lập tuyến và Đang chạy chuyến, đồng thời tính quãng đường Haversine **riêng**. **Cước, biển giới hạn 60 và tuyến đường vẫn là mô phỏng**, không dùng để thu tiền hay dẫn đường.

## Quyền Android 13/14 và pin

1. Trên Home, chạm chip GPS, đọc thông báo rồi nhấn **Bật GPS**. Android hỏi quyền **Vị trí khi sử dụng ứng dụng**. Nếu từ chối, bản đồ không hiển thị marker giả. Hãy bật dịch vụ Vị trí của hệ thống.
2. Khi bắt đầu chuyến, ứng dụng hỏi xác nhận bật GPS cho chuyến. Sau khi được cấp vị trí, Android 13+ có thể hỏi quyền thông báo. Khi GPS chuyến chạy, `geolocator` dùng `ForegroundNotificationConfig` với thông báo **Đang chạy chuyến**. Không xin quyền vị trí mọi lúc `ACCESS_BACKGROUND_LOCATION` vì foreground service được bắt đầu khi app đang ở màn hình trước.
3. AndroidManifest do `ci/scripts/patch_android.py` tạo sẵn `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `WAKE_LOCK`. Android 14 yêu cầu quyền dịch vụ foreground kiểu location. Không thay đổi bộ CI chuẩn.
4. Trong chuyến, `wakelock_plus` giữ màn hình sáng; khi kết thúc hoặc màn chuyến bị đóng, dịch vụ vị trí và wakelock dừng.
5. Trên Redmi/Xiaomi: chạm **Cài đặt pin Xiaomi / Redmi** trên màn chuyến và làm theo hướng dẫn **Pin → Không hạn chế** nếu muốn hạn chế việc hệ thống dừng vị trí khi tắt màn hình. Ứng dụng **không tự động** yêu cầu miễn trừ tối ưu pin hoặc thay đổi cài đặt thay bạn.
6. Nếu bị từ chối vĩnh viễn, vào **Cài đặt → Ứng dụng → BOT TAXIMETER PRO → Quyền → Vị trí**, hoặc bật lại Vị trí hệ thống. Kiểm tra thông báo thường trực khi chuyển app ra nền; Android/MIUI có thể dừng tiến trình nên chưa bảo đảm theo dõi liên tục khi hệ thống đóng ứng dụng.

## Lọc dữ liệu GPS

- `GpsFilter` viết bằng Dart thuần, unit test độc lập.
- Bỏ vị trí sai định dạng, `accuracy > 25 m`, timestamp lùi, tốc độ/bước nhảy suy ra `> 200 km/h`.
- Dùng công thức Haversine bán kính Trái Đất gần đúng 6.371 km. Chỉ cộng quãng đường khi mỗi bước **≥5 m**, tốc độ làm mượt **≥3 km/h**. Khi tạm dừng, vẫn đọc GPS nhưng không cộng quãng đường.
- Tốc độ làm mượt bằng bộ lọc trọng số 70% tốc độ trước và 30% tốc độ mới. Trạng thái `GPS tốt` khi accuracy ≤15m, `GPS yếu` nếu thấp chất lượng/điểm bị loại.
- Tọa độ GPS đã qua lọc mới được truyền vào `SharedMapView` để vẽ mũi tên xe. **Không có quyền hoặc không có fix hợp lệ thì không vẽ marker**. Trung tâm bản đồ ban đầu có thể ở vị trí giới thiệu Bắc Giang, nhưng không được coi đó là vị trí thiết bị.
- Quãng đường, tốc độ, vị trí là số đo GPS tham khảo của điện thoại, **không phải dữ liệu đồng hồ taxi được kiểm định**. Bước 10 mới nối fare engine.

## Tên đường Nominatim và bảo vệ riêng tư

- Nút trên thẻ tên đường cho phép tra **theo yêu cầu tài xế** từ vị trí GPS đã lọc. Bản Step 9 không tự tra tên đường mỗi 50 m.
- `GeocodingProvider` là interface. `NominatimGeocodingProvider` hỗ trợ reverse JSON `/reverse?format=jsonv2&lat=...&lon=...&zoom=18` và nhận URL HTTPS từ `--dart-define=GEOCODING_BASE_URL=https://your-approved-nominatim-host/nominatim`.
- **Mặc định tính năng tên đường qua mạng tắt** nếu không có URL, không gửi tọa độ đến bất cứ geocoder nào. Phải dùng máy chủ Nominatim tự quản lý hoặc nhà cung cấp được phép. Để tránh vi phạm điều khoản ứng dụng theo dõi xe, mã chặn cấu hình máy chủ công cộng `nominatim.openstreetmap.org`.
- Khi được cấu hình: cache kết quả trên ô khoảng 50m, giới hạn ít nhất 1,2 giây giữa yêu cầu, một request tại một thời điểm, cache tối đa 256 ô. Không có auto-complete, không quét ô lưới, không tự retry dồn, timeout 5–6 giây. Có User-Agent định danh ứng dụng và ưu tiên tiếng Việt.
- Thông tin lấy từ dữ liệu OpenStreetMap phải ghi công **© OpenStreetMap contributors**. Máy chủ có thể từ chối hoặc không trả tên đường; không bịa tên.
- Xem chính sách chính thức: https://operations.osmfoundation.org/policies/nominatim/

## Chạy kiểm thử và trên điện thoại

- `flutter test` / Android UI CI `--dart-define=CI=true` luôn sử dụng Canvas demo, `GpsTracker.useMock` không gọi plugin, không xin quyền, không mở network hoặc wakelock. Label `GPS tốt` trong bài smoke chỉ là văn bản mẫu.
- Unit test: `test/gps_filter_test.dart`, `test/road_name_provider_test.dart`, `test/gps_tracker_test.dart`.
- APK chạy thật: cần Google Maps key hợp lệ (xem `docs/GOOGLE_MAPS_SETUP.md`), quyền vị trí, mạng và Google Play Services. Thử ở ngoài trời/đường an toàn khi xe dừng, không thao tác màn hình trong lúc lái.
- Kiểm tra độ chính xác và tốc độ thực, di chuyển chậm / dừng / mất GPS, quyền bị tắt giữa chừng; chỉ số không được nhảy phi thực tế.
- Trong Home, chạm GPS để bật; chạm tên đường để yêu cầu tra cứu nếu có endpoint. Trong chuyến, thử tạm dừng, bật tùy chọn pin, kết thúc, xác minh thông báo GPS nền biến mất.
- Nếu không cấp GPS, Home hiện trạng thái chưa bật và tốc độ 0; tuyến/giá/cước mẫu vẫn chưa có giá trị vận hành.
