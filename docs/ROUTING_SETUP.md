# BỘT TAXIMETER PRO — Bước 11: Dịch vụ tìm địa chỉ và định tuyến

## Mục tiêu và nguồn dữ liệu

- Tìm kiếm Nominatim **chỉ khi nhấn “Tìm thật”**, không autocomplete/truy vấn sau mỗi ký tự.
- Tính tuyến OSRM sau khi nhấn **“Tính tuyến thật”**, hỗ trợ 2 điểm hoặc 1 điểm dừng.
- Xem một hoặc nhiều tuyến OSRM (nếu máy chủ có trả về), polyline trên Google Maps, ETA và các bước rẽ.
- Khoảng cước tham khảo dựa trên FareCalculator của Bước 10; thời gian chờ, BOT và giao thông thực tế không được tự suy đoán.
- Mọi cước của chuyến thực tế vẫn dùng quãng đường GPS đã lọc, **không** lấy khoảng cách OSRM để tính cước đang chạy.

## Quan trọng: điều khoản sử dụng máy chủ

API Nominatim công cộng của OpenStreetMap Foundation không phù hợp để tích hợp mặc định vào ứng dụng taxi/vehicle tracking. Không cấu hình trực tiếp `nominatim.openstreetmap.org`. Chính sách: https://operations.osmfoundation.org/policies/nominatim/

Máy chủ demo OSRM `router.project-osrm.org` chỉ phục vụ thử nghiệm hợp lý, không dùng cho hoạt động taxi thương mại. Tài liệu: https://github.com/Project-OSRM/osrm-backend/wiki/Demo-server

**Dùng Nominatim/OSRM self-hosted hoặc dịch vụ được nhà cung cấp cấp phép**, có HTTPS và chính sách riêng. Đảm bảo chính sách bảo vệ dữ liệu vị trí của tài xế/khách. Không gửi khóa API/địa chỉ nhạy cảm lên repository hoặc log.

## Cấu hình máy chủ được phép

**Cách thuận tiện trên APK GitHub Actions:** Mở **Cài đặt → Máy chủ tìm địa chỉ & định tuyến**, nhập hai URL HTTPS của nhà cung cấp được phép, bấm **Lưu máy chủ tuyến**. Cấu hình lưu trên điện thoại và tự khôi phục sau khi mở lại ứng dụng. Để trống trường URL để tắt dịch vụ. Không cần sửa CI hoặc tạo APK mới khi đổi nhà cung cấp.

Ví dụ xây APK trên máy có Flutter:

```bash
flutter build apk --debug --target-platform android-arm64 \
  --dart-define=GEOCODING_BASE_URL=https://geocoding.example.com \
  --dart-define=ROUTING_BASE_URL=https://routing.example.com
```

Thay `example.com` bằng các máy chủ HTTPS thật đã được cho phép. Đường dẫn geocoding hỗ trợ `/search` và `/reverse`; routing hỗ trợ `/route/v1/driving/{coordinates}` theo chuẩn OSRM. Đừng dùng URL ví dụ để thử mạng.

**CI tiêu chuẩn cố ý không cấu hình 2 URL**: giữ màn mẫu, không gọi mạng, không cần API key/Maps native. Nếu chưa có máy chủ hợp lệ, không hiển thị kết quả tìm kiếm/định tuyến giả như thật.

## Kiểm soát chi phí và lưu lượng

- Nominatim: yêu cầu thủ công, tối đa 5 địa chỉ/lần, cache trong RAM 24 giờ tối đa 64 câu tìm; cách nhau tối thiểu 1,2 giây trong một tiến trình; không có autocomplete.
- OSRM: yêu cầu thủ công, tối đa 3 điểm, cache trong RAM 10 phút tối đa 24 tuyến; không tự gọi khi GPS thay đổi.
- Truy vấn máy chủ do bên vận hành triển khai phải có **rate limit dùng chung giữa các thiết bị**, caching/policy phù hợp và giám sát chi phí. Giới hạn trong app không đảm bảo giới hạn tổng của toàn bộ đội xe.
- Trên Android có thể đổi URL trực tiếp trong Cài đặt mà không cập nhật APK. Với đội xe nhiều máy, vẫn cần proxy/cache/rate-limit chung trên máy chủ do bên vận hành kiểm soát.

## Quy trình kiểm tra Redmi Note 12 Pro

1. Chưa cấu hình URL: Tìm kiếm vẫn hiện mục mẫu, nút “Tìm thật” không gửi mạng; Lập tuyến vẫn báo dữ liệu mẫu.
2. Cấu hình máy chủ HTTPS hợp lệ rồi build APK: nhập địa chỉ, nhấn “Tìm thật”, chọn một kết quả thật và “Chọn điểm đến”.
3. Trên Lập tuyến, bảo đảm GPS đã cấp quyền hoặc chọn điểm xuất phát có tọa độ; nhấn “Tính tuyến thật”.
4. Kiểm tra điểm đi/đến, đường xanh OSRM, danh sách rẽ, ETA và khoảng cước; thử đổi 2D/3D/GT.
5. Thử offline, lỗi 429/500, không tìm được địa chỉ và không tìm được tuyến: app phải báo lỗi, không hiển thị số mẫu như kết quả thật.
6. Chạy an toàn khi đỗ xe hoặc có người đi cùng; ứng dụng không phải hệ thống dẫn đường hay đồng hồ cước được chứng nhận.

Bước 11 hiện hiển thị **chỉ dẫn rẽ của tuyến đã tính**, chưa tự theo dõi tiến độ từng ngã rẽ khi xe di chuyển; đây không phải dẫn đường giọng nói hay cảnh báo giao thông trực tiếp.
