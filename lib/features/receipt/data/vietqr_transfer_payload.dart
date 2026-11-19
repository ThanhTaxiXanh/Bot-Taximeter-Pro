/// VietQR chuyển nhanh NAPAS247 tới tài khoản, mã hóa hoàn toàn offline.
/// Chỉ tạo yêu cầu chuyển khoản; KHÔNG khẳng định tiền đã được chuyển.
class VietQrTransferPayload {
  const VietQrTransferPayload._();

  static bool validRecipient(String bankBin, String account) =>
      RegExp(r'^\d{6}$').hasMatch(bankBin.trim()) &&
      RegExp(r'^\d{6,19}$').hasMatch(account.trim());

  static String noteForTrip(String tripId) {
    final clean = tripId.toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9]'), '');
    if (clean.isEmpty) throw ArgumentError('ID chuyến không hợp lệ');
    final suffix = clean.length > 18
        ? clean.substring(clean.length - 18) : clean;
    return 'TAXI $suffix';
  }

  static String encode({
    required String bankBin,
    required String account,
    int? amountVnd,
    String? note,
  }) {
    final bin = bankBin.trim();
    final number = account.trim();
    if (!validRecipient(bin, number)) {
      throw ArgumentError('BIN ngân hàng hoặc số tài khoản không hợp lệ');
    }
    if (amountVnd != null && (amountVnd <= 0 || amountVnd >= 500000000)) {
      throw ArgumentError.value(amountVnd, 'amountVnd');
    }
    if (note != null && !RegExp(r'^[A-Z0-9 ]{1,25}$').hasMatch(note)) {
      throw ArgumentError('Nội dung chuyển khoản phải là ASCII 1–25 ký tự');
    }

    final beneficiary = _tlv('00', bin) + _tlv('01', number);
    final merchant = _tlv('00', 'A000000727') +
        _tlv('01', beneficiary) + _tlv('02', 'QRIBFTTA');
    final body = _tlv('00', '01') +
        _tlv('01', amountVnd == null ? '11' : '12') +
        _tlv('38', merchant) +
        _tlv('53', '704') +
        (amountVnd == null ? '' : _tlv('54', '$amountVnd')) +
        _tlv('58', 'VN') +
        (note == null ? '' : _tlv('62', _tlv('08', note)));
    final checksumInput = '${body}6304';
    return checksumInput + _crc16(checksumInput);
  }

  static bool checksumValid(String payload) {
    if (payload.length < 8 ||
        !payload.substring(payload.length - 8, payload.length - 4)
            .endsWith('6304')) return false;
    try {
      final source = payload.substring(0, payload.length - 4);
      return _crc16(source) == payload.substring(payload.length - 4);
    } catch (_) {
      return false;
    }
  }

  static String _tlv(String id, String value) {
    if (value.length > 99) throw ArgumentError('Trường QR quá dài');
    return '$id${value.length.toString().padLeft(2, '0')}$value';
  }

  /// CRC16/CCITT-FALSE: polynomial 0x1021, init 0xFFFF, xorout 0.
  static String _crc16(String input) {
    var crc = 0xFFFF;
    for (final byte in input.codeUnits) {
      if (byte > 127) throw ArgumentError('Payload QR chỉ cho phép ASCII');
      crc ^= (byte << 8);
      for (var bit = 0; bit < 8; bit++) {
        crc = ((crc & 0x8000) != 0)
            ? ((crc << 1) ^ 0x1021) & 0xFFFF
            : (crc << 1) & 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
