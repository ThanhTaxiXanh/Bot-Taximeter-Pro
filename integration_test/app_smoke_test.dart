// Kiểm thử khói giao diện chạy trên máy ảo Android 13 trong GitHub Actions.
// Chỉ dựa vào chữ hiển thị (nhãn tiếng Việt trong Master Prompt), không cần Key.
// Chạy với: flutter test integration_test --dart-define=CI=true
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bot_taximeter_pro/main.dart' as app;

/// Khi CI=true, ứng dụng nên bỏ qua hộp thoại xin quyền và dùng vị trí/bản đồ giả
/// (xem mục 1B trong Master Prompt).
const bool kCI = bool.fromEnvironment('CI');

/// Không dùng pumpAndSettle vì hiệu ứng phát sáng chạy vô hạn sẽ không bao giờ "yên".
Future<void> pumpFor(WidgetTester tester, {int steps = 15}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> startApp(WidgetTester tester) async {
  app.main();
  await pumpFor(tester, steps: 30);
}

Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  expect(finder, findsWidgets, reason: 'Không thấy nút/chữ "$text"');
  await tester.tap(finder.first);
  await pumpFor(tester);
}

void expectText(String text) {
  expect(find.textContaining(text), findsWidgets,
      reason: 'Không thấy chữ "$text" trên màn hình');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Màn 1 hiển thị đủ thành phần chính', (tester) async {
    await startApp(tester);
    expect(find.textContaining('DRIVER PRO', findRichText: true), findsWidgets);
    for (final label in [
      'Tìm kiếm',
      'Tuyến đường',
      'Doanh thu',
      'Cài đặt',
      'Bắt đầu',
      'Lịch sử',
    ]) {
      expectText(label);
    }
    expect(tester.takeException(), isNull);
  });

  // Mỗi cặp: nút ở Màn 1 -> chữ phải thấy ở màn đích.
  final navCases = <String, String>{
    'Tìm kiếm': 'Kết quả tìm kiếm',
    'Tuyến đường': 'Lập tuyến đường',
    'Doanh thu': 'Các cuốc xe gần đây',
    'Lịch sử': 'Các cuốc xe gần đây',
    'Cài đặt': 'Lưu cài đặt',
  };
  navCases.forEach((button, expected) {
    testWidgets('Nút "$button" mở đúng màn hình', (tester) async {
      await startApp(tester);
      await tapText(tester, button);
      expectText(expected);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Luồng chuyến đi: Bắt đầu -> Tạm dừng -> Tiếp tục -> Kết thúc -> Biên lai',
      (tester) async {
    await startApp(tester);
    await tapText(tester, 'Bắt đầu');
    expectText('Tổng cước');
    expectText('Thời gian chờ');

    await tapText(tester, 'Tạm dừng');
    expectText('Tiếp tục');
    await tapText(tester, 'Tiếp tục');

    await tapText(tester, 'Kết thúc');
    await tapText(tester, 'Xác nhận'); // nút trong hộp thoại xác nhận
    expectText('Biên lai chuyến đi');
    expect(tester.takeException(), isNull);
  });
}
