import 'dart:math' as math;

/// Biểu phí do tài xế cấu hình, không phải biểu phí đã được kiểm định.
class FareConfig {
  const FareConfig({
    this.openingVnd = 30000,
    this.firstTierVndPerKm = 13000,
    this.secondTierVndPerKm = 11500,
    this.thirdTierVndPerKm = 10000,
    this.waitVndPerHour = 30000,
    this.freeWaitMinutes = 5,
  });

  final int openingVnd;
  final int firstTierVndPerKm;
  final int secondTierVndPerKm;
  final int thirdTierVndPerKm;
  final int waitVndPerHour;
  final int freeWaitMinutes;

  bool get isValid =>
      openingVnd >= 0 && firstTierVndPerKm >= 0 &&
      secondTierVndPerKm >= 0 && thirdTierVndPerKm >= 0 &&
      waitVndPerHour >= 0 && freeWaitMinutes >= 0 &&
      freeWaitMinutes <= 1440;

  Map<String, int> toJson() => <String, int>{
    'opening': openingVnd, 'tier1': firstTierVndPerKm,
    'tier2': secondTierVndPerKm, 'tier3': thirdTierVndPerKm,
    'waitHour': waitVndPerHour, 'freeWait': freeWaitMinutes,
  };

  factory FareConfig.fromJson(Map<String, dynamic> map) {
    int number(String key, int fallback) =>
        map[key] is int ? map[key] as int : fallback;
    final result = FareConfig(
      openingVnd: number('opening', 30000),
      firstTierVndPerKm: number('tier1', 13000),
      secondTierVndPerKm: number('tier2', 11500),
      thirdTierVndPerKm: number('tier3', 10000),
      waitVndPerHour: number('waitHour', 30000),
      freeWaitMinutes: number('freeWait', 5),
    );
    if (!result.isValid) throw ArgumentError('Biểu phí không hợp lệ');
    return result;
  }
}

class FareBreakdown {
  const FareBreakdown({
    required this.opening, required this.tier1, required this.tier2,
    required this.tier3, required this.waitFee, required this.rounded,
    required this.toll, required this.total, required this.chargeableWaitSec,
  });
  final int opening;
  final double tier1, tier2, tier3, waitFee;
  final int rounded, toll, total, chargeableWaitSec;
}

/// Cách làm tròn riêng trong Master Prompt: r = 500 vẫn làm tròn XUỐNG.
int roundVnd(num raw) {
  if (!raw.isFinite || raw < 0) {
    throw ArgumentError.value(raw, 'raw', 'Tiền phải >= 0 và hữu hạn');
  }
  final thousands = (raw / 1000).floor();
  final remainder = raw - thousands * 1000;
  return (thousands + (remainder > 500 ? 1 : 0)) * 1000;
}

class FareCalculator {
  const FareCalculator(this.config);
  final FareConfig config;

  FareBreakdown calculate({
    required double distanceKm,
    required int waitingSeconds,
    int tollFee = 0,
  }) {
    if (!config.isValid || !distanceKm.isFinite || distanceKm < 0 ||
        waitingSeconds < 0 || tollFee < 0) {
      throw ArgumentError('Dữ liệu cước không hợp lệ');
    }
    final a = math.max(0.0, math.min(distanceKm, 30.0) - 1.5) *
        config.firstTierVndPerKm;
    final b = math.max(0.0, math.min(distanceKm, 50.0) - 30.0) *
        config.secondTierVndPerKm;
    final c = math.max(0.0, distanceKm - 50.0) *
        config.thirdTierVndPerKm;
    final chargeable = math.max(
        0, waitingSeconds - config.freeWaitMinutes * 60);
    final wait = chargeable / 3600.0 * config.waitVndPerHour;
    final raw = config.openingVnd + a + b + c + wait;
    // Tránh sai số nhị phân tại r=500 sau phép nhân km thập phân.
    final rounded = roundVnd(double.parse(raw.toStringAsFixed(6)));
    return FareBreakdown(
      opening: config.openingVnd, tier1: a, tier2: b, tier3: c,
      waitFee: wait, chargeableWaitSec: chargeable,
      rounded: rounded, toll: tollFee, total: rounded + tollFee,
    );
  }

  /// Ước tính theo tuyến khi có GPS + tuyến thật, chưa dùng tại Bước 10.
  (int, int) estimate(double routeKm) {
    if (!routeKm.isFinite || routeKm < 0) {
      throw ArgumentError.value(routeKm, 'routeKm');
    }
    return (
      calculate(distanceKm: routeKm * .95, waitingSeconds: 0).rounded,
      calculate(distanceKm: routeKm * 1.15, waitingSeconds: 0).rounded,
    );
  }
}

String formatVnd(int vnd) =>
    '${vnd.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} đ';

String formatKm(double km) => '${km.toStringAsFixed(2).replaceAll('.', ',')} km';
