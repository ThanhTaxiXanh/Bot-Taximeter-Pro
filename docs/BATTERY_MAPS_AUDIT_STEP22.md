# Bước 22 — Kiểm toán pin và chi phí Google Maps

**Ngày 19/11/2026.** Theo Master Prompt mục 3, mục 6 và mục 10.14: giữ Maps SDK for Android không dùng Map ID; chỉ thu GPS nhiều khi có chuyến; hướng dẫn người dùng khóa key/giám sát chi phí; hoàn thiện README.

## 1. Điều chỉnh tiêu thụ pin

| Trạng thái | GPS trước | GPS sau Bước 22 | Mục đích |
|---|---|---|---|
| Home, chỉ xem vị trí, tài xế chủ động bật GPS | 1 giây, `distanceFilter: 0` | **5 giây, `distanceFilter: 10` m**, accuracy `high`, `maxUpdateAge: 10` giây | Giảm tần suất cập nhật và wake-up khi chưa tính cước |
| Chuyến đang chạy (kể cả Waiting) | 1 giây, 0 m, `bestForNavigation`, foreground notification và wakelock | **Giữ nguyên** 1 giây, 0 m, `bestForNavigation`, `maxUpdateAge: 5` giây, foreground notification và wakelock | Không ảnh hưởng điều kiện lọc GPS/khoảng cách tính cước |
| Ứng dụng ra nền khi chỉ xem GPS Home | Vẫn chạy đến khi người dùng dừng | **Tự dừng luồng GPS xem trước** khi app `paused`, không có chuyến/không khởi động GPS | Tránh dùng pin nền không cần thiết |
| Ứng dụng ra nền khi có chuyến | Tiếp tục theo dõi foreground service | **Tiếp tục như cũ** | Không làm gián đoạn cuốc xe; MIUI/Android vẫn có thể giới hạn nền |

**Giới hạn kỹ thuật:** `distanceFilter` và `intervalDuration` là các thông số yêu cầu từ OS, **không cam kết** tiết kiệm chính xác bao nhiêu phần trăm hoặc luôn được Android tuân theo. Khi trở lại Home, GPS xem trước đã dừng **không tự bật lại**, muốn xem xe thật thì chạm chip GPS. `GpsFilter`, ngưỡng sai số, state machine, cước và snapshot **không thay đổi**. Tuyệt đối không tự tắt dịch vụ GPS chuyến khi app chuyển nền.

Mã: `lib/features/map_tracking/data/gps_tracker.dart` khai báo `GpsPowerPolicy`; `lib/main.dart` theo dõi `AppLifecycleState.paused` bằng `WidgetsBindingObserver`; `test/gps_tracker_test.dart` kiểm thử chính sách cho Home/chuyến, 5 trường hợp cấm dừng GPS.

## 2. Kiểm toán mã Google Maps đang sử dụng

- `lib/shared/shared_map_view.dart` dùng duy nhất `google_maps_flutter` với `GoogleMap`, `buildingsEnabled`, `trafficEnabled`, `style` JSON từ `assets/map_styles/`. **Không có `mapId`/Cloud-based styling, Street View hoặc API Google HTTP có tính phí** trong phần mã đã kiểm tra.
- Giao diện xem trước của các màn khác dùng CustomPainter, không tạo ảnh Google Static Maps.
- Nominatim/OSRM không phải Google Maps API và mặc định không tự gọi máy chủ công cộng; chỉ dùng URL HTTPS do người dùng chủ động cấu hình.
- Tránh thêm `mapId`, `cloudMapId`, `Map Tiles API`, `Places API`, `Routes API` hoặc `Geocoding API` vào dự án; nếu cần, phải đánh giá lại bảng giá và quyền truy cập.
- Google hiện niêm yết SKU **Maps SDK** miễn phí không giới hạn; **Dynamic Maps** do map ID có tính phí. Giá/điều khoản có thể đổi; cần kiểm tra hàng tháng chứ không tuyên bố chi phí tuyệt đối bằng 0.

Nguồn chính thức (truy cập ngày 19/11/2026):
- [Google Maps Platform pricing](https://developers.google.com/maps/billing-and-pricing/pricing) — SKU `Maps SDK`, free usage unlimited.
- [Maps SDK for Android: Usage and Billing](https://developers.google.com/maps/documentation/android-sdk/usage-and-billing).
- [How to create map IDs](https://developers.google.com/maps/documentation/android-sdk/map-ids/get-map-id) — map ID kích hoạt SKU Dynamic Maps có phí.
- [Manage costs: budgets, quotas](https://developers.google.com/maps/billing-and-pricing/manage-costs).
- [Get/restrict API key for Android SDK](https://developers.google.com/maps/documentation/android-sdk/get-api-key).

## 3. Google Cloud Console — thao tác trên điện thoại

1. Vào [Google Cloud Console](https://console.cloud.google.com/) bằng trình duyệt (có thể bật chế độ **Trang web cho máy tính**). Chọn đúng **project** mà GitHub secret `MAPS_API_KEY` đang sử dụng. Không dán key công khai.
2. **APIs & Services → Enabled APIs & services**: đối chiếu danh sách; chỉ giữ **Maps SDK for Android** cho ứng dụng này nếu không có nhu cầu khác. Không dùng Cloud Map ID.
3. **APIs & Services → Credentials → chọn Android Maps key**: `Application restrictions = Android apps`, nhập package **`vn.bottaximeter.bot_taximeter_pro`** và SHA-1 từ Issue #1 của bản APK đang cài. CI #40 dùng SHA-1 debug `8E:14:0E:88:F1:F2:BD:56:82:61:CF:42:EA:07:A2:F5:30:C5:DA:B4`. Chữ ký khác phải thêm fingerprint tương ứng.
4. `API restrictions = Restrict key`, chỉ chọn **Maps SDK for Android**; lưu thay đổi. Giữ `MAPS_API_KEY` trong **GitHub → Repository Settings → Secrets and variables → Actions**; không sửa workflow/manifest thủ công.
5. **Billing → Budgets & alerts**: tạo ngân sách và email cảnh báo theo mức phù hợp. **Budget alerts không có chức năng ngắt tính phí**; xem **Billing Reports** và usage theo SKU, đặc biệt Dynamic Maps/Places/Routes, theo chu kỳ.
6. **APIs & Services → Quotas & System Limits**: xem quota nếu dịch vụ có giới hạn có thể cấu hình. Quota/budget không bảo đảm mọi chi phí về 0; thiết lập hợp lý để tránh ảnh hưởng bản đồ của ứng dụng.
7. Nếu bản đồ trống, kiểm tra billing, Android package, SHA-1 và Google Play Services trước khi mở API ngoài phạm vi. Trong CI bản đồ là Canvas nên không kiểm thử key trên Cloud.

**Khác biệt giữa Master Prompt và mã thực tế:** Master Prompt phiên bản đầu dùng ví dụ package `vn.bottaximeter.pro`, nhưng repository đang build **`vn.bottaximeter.bot_taximeter_pro`** trong `lib/core/app_config.dart` và CI; cần dùng **package thực tế** khi giới hạn khóa.

## 4. Nghiệm thu thực địa / chưa xác nhận

- Cài **đè** APK sau khi CI của Bước 22 đạt. Trong Home bật GPS, cho app vào nền rồi trở lại: GPS xem trước phải dừng, có thể bật lại thủ công.
- Bắt đầu chuyến, cấp quyền vị trí/thông báo, cho app ra nền ngắn: thông báo thường trực vẫn có; quay lại phải giữ trạng thái chuyến, đồng hồ cước tham khảo không bị reset. Kết thúc và xác minh GPS/wakelock dừng.
- Trên Redmi/Xiaomi, thử với màn hình tắt, vị trí chính xác và thiết lập Pin → Không hạn chế khi thực sự cần; ứng dụng không tự xin quyền bỏ tối ưu pin.
- Google Maps thực trên điện thoại cần key hợp lệ; so sánh Cloud Billing Reports theo SKU. Không thể xác minh hoá đơn/tiết kiệm pin thật bằng CI.
- Nếu có bất thường về quãng đường hoặc cập nhật nền, ưu tiên an toàn của chuyến đi và GPS trước tiết kiệm pin; không thay `GpsFilter`/fare engine.

**CI trước Bước 22:** #40, commit `c0abdce`, đạt 4/4 theo Issue #1. **CI của commit Bước 22 chưa xác nhận khi tạo thay đổi này.** Không tuyên bố điện thoại thật đã được kiểm thử.
