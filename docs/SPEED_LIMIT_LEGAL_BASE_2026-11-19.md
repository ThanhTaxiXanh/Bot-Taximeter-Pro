# BỘT TAXIMETER PRO — Bước 17: nền quy tắc giới hạn tốc độ

**Đối chiếu ngày 19/11/2026.** Chỉ bổ sung logic Dart thuần, KHÔNG kết nối với cảnh báo tốc độ đang hoạt động. Màn hình hiện hành vẫn chỉ có cảnh báo ngưỡng cá nhân.

## Căn cứ đã tham khảo

- Thông tư 38/2024/TT-BGTVT, Điều 6 và Điều 9: https://congbao.chinhphu.vn/van-ban/thong-tu-so-38-2024-tt-bgtvt-43378.htm
- Văn bản hợp nhất 74/2026/VBHN-TT-BXD (15/09/2026), bao gồm sửa đổi 09/2025/TT-BXD: https://moc.gov.vn/vn/Pages/ChiTietVanBan.aspx?vID=5060
- QCVN 41:2024/BGTVT, ban hành qua Thông tư 51/2024/TT-BGTVT: https://vanban.chinhphu.vn/?docid=211908&pageid=27160
- Nghị định 168/2024/NĐ-CP, Điều 6 (mức vượt tốc độ): https://xaydungchinhsach.chinhphu.vn/toan-van-nghi-dinh-168-2024-nd-cp-quy-dinh-xu-phat-vi-pham-hanh-chinh-ve-trat-tu-atgt-duong-bo-119241231164556785.htm
- Nghị định 238/2026/NĐ-CP (sửa đổi 168/2024): https://congbao.chinhphu.vn/van-ban/nghi-dinh-so-238-2026-nd-cp-469913.htm

Tháng 11/2026 có **dự thảo** sửa Thông tư 38/2024 đang được lấy ý kiến; dự thảo không được coi là luật có hiệu lực. Khi kích hoạt trên xe phải kiểm tra lại văn bản pháp lý mới nhất.

## Giới hạn phạm vi

- Tệp `lib/features/speed_limit/speed_rules.dart` chứa 16 hàng Điều 6 (4 nhóm xe × 2 khu vực × 2 kiểu đường), mỗi hàng có `legalBasis`, `articleRef`, `effectiveFrom`. Chỉ áp dụng cho nhóm xe Điều 6; xe thuộc Điều 7–8 không tự suy theo bảng này.
- Theo Điều 6, ô tô chở người đến **28 chỗ không kể người lái** là nhóm khác ô tô trên 28 chỗ. Trường cài đặt hiện tại 'Xe đến 30 chỗ' chưa đủ thông tin để tự phân loại; Bước 18 phải xử lý rõ ràng.
- Tệp `lib/features/speed_limit/speed_limit_engine.dart` ưu tiên `manual` → `posted` → `rule`/`ruleGuess` → `unknown`. Không đủ ngữ cảnh thì trả `--`, không cảnh báo. OSM, dữ liệu biển chưa xác minh và khu vực suy đoán chỉ hiển thị có dấu `~`.
- Cao tốc theo Điều 9: mức trần chung 120 km/h, sàn chung 60 km/h có ngoại lệ cao tốc thiết kế 60 km/h và quy định theo tổ chức giao thông. Không tự áp 120/60 cho đoạn cao tốc chưa xác minh biển.
- `test/speed_limit_rules_test.dart` kiểm tra 16 tổ hợp, ưu tiên nguồn, unknown, cao tốc và biên mức vượt 5/10/20/35 km/h.
- Không dùng CSV/GeoJSON biển báo chưa kiểm định làm giới hạn pháp lý. Không đánh đồng cảnh báo với kết luận vi phạm hoặc xử phạt.

## Bước tiếp theo: 18 (chỉ khi người dùng yêu cầu)

Tích hợp ngữ cảnh đường/biển được xác minh, UI và ghi đè theo đoạn; bảo vệ GPS, cảnh báo vượt liên tục ít nhất 3 giây và âm/rung cách nhau tối thiểu 15 giây. Không thay đổi GPS, cước, SQLite/PDF/VietQR, package, theme hoặc CI trong Bước 17.

**CI:** Mốc được đọc trước khi commit là CI #30 đạt 4/4. Chưa có bằng chứng CI cho mã Bước 17; chỉ xác nhận sau khi xem Issue #1 và log của lượt chạy đúng commit.