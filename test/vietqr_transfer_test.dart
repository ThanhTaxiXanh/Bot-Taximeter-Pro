import 'package:flutter_test/flutter_test.dart';

import 'package:bot_taximeter_pro/features/receipt/data/vietqr_transfer_payload.dart';

void main() {
  test('Kiểm CRC16 bằng chuỗi mẫu trong tài liệu VietQR v1.0', () {
    const example = '00020101021138570010A0000007270127000697040'
        '3011200110123456780208QRIBFTTA53037045802VN6304F4E5';
    expect(VietQrTransferPayload.checksumValid(example), isTrue);
    expect(VietQrTransferPayload.checksumValid(
        '${example.substring(0, example.length - 4)}FFFF'), isFalse);
  });

  test('Mã yêu cầu chuyển khoản có đúng TLV, tiền VND và CRC', () {
    final payload = VietQrTransferPayload.encode(
      bankBin: '970403', account: '0123456789',
      amountVnd: 180000, note: 'TAXI TTX001',
    );
    expect(payload,
      '00020101021238540010A000000727012400069704030110'
      '01234567890208QRIBFTTA530370454061800005802VN'
      '62150811TAXI TTX0016304E593');
    expect(VietQrTransferPayload.checksumValid(payload), isTrue);
    expect(payload, contains('5406180000'));
    expect(payload, contains('5303704'));
    expect(payload, contains('0208QRIBFTTA'));
  });

  test('Không bỏ số 0 đầu của tài khoản, không dùng note có dấu', () {
    final payload = VietQrTransferPayload.encode(
      bankBin: '970403', account: '001234567890',
      amountVnd: 30000, note: VietQrTransferPayload.noteForTrip(
        'TTX-1763545000000'),
    );
    expect(payload, contains('0112001234567890'));
    expect(VietQrTransferPayload.checksumValid(payload), isTrue);
    expect(VietQrTransferPayload.noteForTrip('TTX-1763545000000'),
        'TAXI TTX1763545000000');
  });

  test('Chặn dữ liệu người nhận sai, tiền âm hoặc vượt hạn mức', () {
    expect(() => VietQrTransferPayload.encode(
        bankBin: 'VCB', account: '1234567890', amountVnd: 10000),
        throwsArgumentError);
    expect(() => VietQrTransferPayload.encode(
        bankBin: '970403', account: '12345', amountVnd: 10000),
        throwsArgumentError);
    expect(() => VietQrTransferPayload.encode(
        bankBin: '970403', account: '0123456789', amountVnd: 0),
        throwsArgumentError);
    expect(() => VietQrTransferPayload.encode(
        bankBin: '970403', account: '0123456789', amountVnd: 500000000),
        throwsArgumentError);
    expect(() => VietQrTransferPayload.encode(
        bankBin: '970403', account: '0123456789',
        amountVnd: 60000, note: 'CUỐC TAXI'),
        throwsArgumentError);
    expect(() => VietQrTransferPayload.noteForTrip('!?-'), throwsArgumentError);
  });
}
