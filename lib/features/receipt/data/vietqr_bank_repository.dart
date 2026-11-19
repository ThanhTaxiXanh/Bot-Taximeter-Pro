import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../../history/data/taximeter_database.dart';
import '../../map_tracking/data/gps_tracker.dart';

class VietQrBank {
  const VietQrBank({required this.bin, required this.shortName,
      required this.name, required this.code});
  final String bin, shortName, name, code;

  static VietQrBank? decode(Object? raw) {
    if (raw is! Map) return null;
    final bin = raw['bin']?.toString().trim() ?? '';
    final short = raw['shortName']?.toString().trim() ?? '';
    final name = raw['name']?.toString().trim() ?? '';
    final code = raw['code']?.toString().trim() ?? '';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(bin) ||
        short.isEmpty || short.length > 80 ||
        name.isEmpty || name.length > 180 ||
        code.isEmpty || code.length > 32 ||
        (raw['transferSupported'] != 1 &&
            raw['transferSupported'] != '1')) return null;
    return VietQrBank(bin: bin, shortName: short, name: name, code: code);
  }

  Map<String, Object> toMap() => <String, Object>{
    'bin': bin, 'short_name': shortName,
    'full_name': name, 'bank_code': code,
  };

  factory VietQrBank.fromMap(Map<String, Object?> row) => VietQrBank(
    bin: row['bin'] as String,
    shortName: row['short_name'] as String,
    name: row['full_name'] as String,
    code: row['bank_code'] as String,
  );
}

abstract class BankCache {
  Future<List<VietQrBank>> read();
  Future<void> replace(List<VietQrBank> rows);
}

class MemoryBankCache implements BankCache {
  List<VietQrBank> saved = <VietQrBank>[];
  @override
  Future<List<VietQrBank>> read() async => List<VietQrBank>.of(saved);
  @override
  Future<void> replace(List<VietQrBank> rows) async {
    saved = List<VietQrBank>.of(rows);
  }
}

class SqliteBankCache implements BankCache {
  @override
  Future<List<VietQrBank>> read() async {
    final db = await TaximeterDatabase.instance;
    final rows = await db.query('banks', orderBy: 'short_name ASC');
    return rows.map(VietQrBank.fromMap).toList(growable: false);
  }

  @override
  Future<void> replace(List<VietQrBank> rows) async {
    final db = await TaximeterDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete('banks');
      for (final row in rows) {
        await txn.insert('banks', row.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}

typedef BankApiFetch = Future<Object?> Function();
typedef BankSeedLoader = Future<String> Function();

/// Cache trên máy, seed offline; mạng chỉ khi tài xế bấm làm mới.
class VietQrBankRepository {
  VietQrBankRepository({BankCache? cache, BankApiFetch? fetch,
      BankSeedLoader? seedLoader})
      : _cache = cache ??
            (GpsTracker.useMock ? MemoryBankCache() : SqliteBankCache()),
        _fetch = fetch ?? _getFromVietQr,
        _customFetch = fetch != null,
        _seedLoader = seedLoader ?? _loadBundledSeed;

  final BankCache _cache;
  final BankApiFetch _fetch;
  final bool _customFetch;
  final BankSeedLoader _seedLoader;

  static List<VietQrBank> parse(Object? raw) {
    if (raw is! Map || raw['code']?.toString() != '00' ||
        raw['data'] is! List) {
      throw const FormatException('Danh sách ngân hàng không hợp lệ');
    }
    final unique = <String, VietQrBank>{};
    for (final value in raw['data'] as List) {
      final bank = VietQrBank.decode(value);
      if (bank != null) unique.putIfAbsent(bank.bin, () => bank);
    }
    final banks = unique.values.toList()
      ..sort((a, b) => a.shortName.compareTo(b.shortName));
    if (banks.length < 5) {
      throw const FormatException('Danh sách ngân hàng quá ít hoặc sai');
    }
    return banks;
  }

  Future<List<VietQrBank>> offline() async {
    try {
      final saved = await _cache.read();
      if (saved.isNotEmpty) return saved;
    } catch (_) {
      // Không mở được SQLite vẫn có dữ liệu seed tham khảo.
    }
    final seed = parse(jsonDecode(await _seedLoader()));
    try { await _cache.replace(seed); } catch (_) {}
    return seed;
  }

  Future<List<VietQrBank>> refresh() async {
    // Không bao giờ gọi mạng trong CI hay widget test (trừ fake fetch).
    if (GpsTracker.useMock && !_customFetch) {
      throw StateError('Không gọi API ngân hàng trong CI');
    }
    final banks = parse(await _fetch());
    // Chỉ thay bảng cũ nếu tải và kiểm tra dữ liệu thành công.
    await _cache.replace(banks);
    return banks;
  }

  static Future<String> _loadBundledSeed() =>
      rootBundle.loadString('assets/data/vietqr_banks_seed.json');

  static Future<Object?> _getFromVietQr() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 7);
    try {
      final request = await client.getUrl(
        Uri.parse('https://api.vietqr.io/v2/banks'),
      ).timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close()
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StateError('VietQR HTTP ' + response.statusCode.toString());
      }
      final body = await response.transform(utf8.decoder).join()
          .timeout(const Duration(seconds: 10));
      if (body.length > 512000) {
        throw const FormatException('Danh sách VietQR quá lớn');
      }
      return jsonDecode(body);
    } finally {
      client.close(force: true);
    }
  }
}
