import 'package:flutter_test/flutter_test.dart';
import 'package:bot_taximeter_pro/features/fare_meter/fare_calculator.dart';

void main() {
  test('roundVnd: r=500 cũng làm tròn xuống', () {
    for (final r in <int>[0, 1, 499, 500]) {
      expect(roundVnd(71000 + r), 71000);
    }
    for (final r in <int>[501, 999]) {
      expect(roundVnd(71000 + r), 72000);
    }
    expect(roundVnd(71500), 71000);
    expect(roundVnd(71501), 72000);
    expect(roundVnd(71499), 71000);
    expect(() => roundVnd(-1), throwsArgumentError);
    expect(() => roundVnd(double.nan), throwsArgumentError);
  });

  const calculator = FareCalculator(FareConfig());
  test('Bậc mở cửa / 1,5 km / 30 km / 50 km', () {
    int fare(double d) => calculator.calculate(
        distanceKm: d, waitingSeconds: 0).total;
    expect(fare(0), 30000);
    expect(fare(1.5), 30000);
    expect(fare(30), 400000); // raw 400.500: làm tròn xuống.
    expect(fare(50), 630000);
    expect(fare(50.1), 631000); // raw 631.500.
    expect(fare(50.2), 632000);
    expect(calculator.calculate(distanceKm: 50,
        waitingSeconds: 0).tier3, 0);
  });

  test('Chờ miễn phí tổng 5 phút, trên ngưỡng mới tính', () {
    int fare(int seconds) => calculator.calculate(
        distanceKm: 0, waitingSeconds: seconds).total;
    expect(fare(299), 30000);
    expect(fare(300), 30000);
    expect(fare(360), 30000); // raw 30.500: xuống.
    expect(fare(361), 31000);
    expect(fare(420), 31000);
    final details = calculator.calculate(
        distanceKm: 0, waitingSeconds: 420);
    expect(details.chargeableWaitSec, 120);
    expect(details.waitFee, closeTo(1000, 0.01));
  });

  test('BOT cộng SAU làm tròn', () {
    final fare = calculator.calculate(distanceKm: 30,
        waitingSeconds: 0, tollFee: 7500);
    expect(fare.rounded, 400000);
    expect(fare.total, 407500);
  });

  test('Biểu phí được cấu hình, validate và estimate', () {
    const config = FareConfig(freeWaitMinutes: 0, openingVnd: 35000);
    expect(config.isValid, true);
    expect(FareConfig.fromJson(config.toJson()).toJson(), config.toJson());
    expect(const FareConfig(freeWaitMinutes: -1).isValid, false);
    const custom = FareCalculator(config);
    expect(custom.calculate(distanceKm: 0,
        waitingSeconds: 360).total, 38000);
    final range = calculator.estimate(10);
    expect(range.$1, lessThan(range.$2));
    expect(() => calculator.calculate(
        distanceKm: -1, waitingSeconds: 0), throwsArgumentError);
  });
}
