import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/receipt/data/vietqr_bank_repository.dart';
import 'package:bot_taximeter_pro/features/receipt/presentation/vietqr_bank_picker.dart';

List<Map<String, Object>> sampleBanks() => <Map<String, Object>>[
  <String, Object>{
    'bin': '970415', 'shortName': 'VietinBank',
    'name': 'Ngân hàng Công thương', 'code': 'ICB',
    'transferSupported': 1,
  },
  <String, Object>{
    'bin': '970436', 'shortName': 'Vietcombank',
    'name': 'Ngân hàng Ngoại thương', 'code': 'VCB',
    'transferSupported': 1,
  },
  <String, Object>{
    'bin': '970418', 'shortName': 'BIDV',
    'name': 'Ngân hàng Đầu tư', 'code': 'BIDV',
    'transferSupported': 1,
  },
  <String, Object>{
    'bin': '970405', 'shortName': 'Agribank',
    'name': 'Ngân hàng Nông nghiệp', 'code': 'VBA',
    'transferSupported': 1,
  },
  <String, Object>{
    'bin': '970407', 'shortName': 'Techcombank',
    'name': 'Ngân hàng Kỹ thương', 'code': 'TCB',
    'transferSupported': 1,
  },
  <String, Object>{
    'bin': '970422', 'shortName': 'MBBank',
    'name': 'Ngân hàng Quân đội', 'code': 'MB',
    'transferSupported': 1,
  },
];

Object catalog([List<Map<String, Object>>? banks]) => <String, Object>{
  'code': '00', 'data': banks ?? sampleBanks(),
};

void main() {
  test('Tải seed ngoại tuyến và cache; không tự gọi API', () async {
    final cache = MemoryBankCache();
    var onlineCalls = 0, seedCalls = 0;
    final repo = VietQrBankRepository(
      cache: cache,
      seedLoader: () async {
        seedCalls++;
        return jsonEncode(catalog());
      },
      fetch: () async {
        onlineCalls++;
        return catalog();
      },
    );
    final first = await repo.offline();
    expect(first.length, 6);
    expect(first.any((b) => b.bin == '970436'), isTrue);
    expect((await cache.read()).length, 6);
    final second = await repo.offline();
    expect(second.length, 6);
    expect(seedCalls, 1);
    expect(onlineCalls, 0);
  });

  test('Cập nhật thành công dùng danh sách API; lỗi giữ cache cũ', () async {
    final cache = MemoryBankCache();
    var invalid = false;
    final repo = VietQrBankRepository(
      cache: cache,
      seedLoader: () async => jsonEncode(catalog()),
      fetch: () async => invalid ? <String, Object>{
        'code': '99', 'data': <Object>[],
      } : catalog(),
    );
    await repo.offline();
    final before = await cache.read();
    expect((await repo.refresh()).length, 6);
    invalid = true;
    await expectLater(repo.refresh(), throwsFormatException);
    expect((await cache.read()).map((b) => b.bin),
        before.map((b) => b.bin));
  });

  test('Từ chối BIN sai, mục không chuyển tiền, danh sách rỗng', () {
    final raw = sampleBanks();
    raw.add(<String, Object>{
      'bin': '97ABCD', 'shortName': 'Sai',
      'name': 'Sai', 'code': 'BAD', 'transferSupported': 1,
    });
    raw.add(<String, Object>{
      'bin': '971011', 'shortName': 'Ví không chuyển',
      'name': 'Không nhận VietQR', 'code': 'WALLET',
      'transferSupported': 0,
    });
    raw.add(raw.first);
    final result = VietQrBankRepository.parse(catalog(raw));
    expect(result.length, 6);
    expect(result.where((b) => b.bin == '970415').length, 1);
    expect(result.any((b) => b.bin == '971011'), isFalse);
    expect(() => VietQrBankRepository.parse(<String, Object>{
      'code': '00', 'data': <Object>[],
    }), throwsFormatException);
  });

  testWidgets('Chọn tên và BIN từ danh sách không tự chuyển tiền',
      (tester) async {
    VietQrBank? selected;
    final repo = VietQrBankRepository(
      cache: MemoryBankCache(),
      seedLoader: () async => jsonEncode(catalog()),
      fetch: () async => throw StateError('Không gọi mạng trong test'),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(
        child: VietQrBankPicker(
          repository: repo, onSelected: (b) => selected = b,
        ),
      )),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    final button = find.byKey(const Key('choose_vietqr_bank'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Chọn ngân hàng VietQR'), findsOneWidget);
    final item = find.text('Agribank');
    await tester.tap(item);
    await tester.pump();
    expect(selected?.bin, '970405');
    expect(selected?.shortName, 'Agribank');
    expect(find.byKey(const Key('refresh_vietqr_banks')), findsNothing);
  });
}
