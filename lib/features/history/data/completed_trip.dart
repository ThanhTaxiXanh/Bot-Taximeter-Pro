import '../../fare_meter/fare_calculator.dart';

/// Dữ liệu cước GPS tham khảo của một chuyến đã hoàn thành.
class CompletedTrip {
  const CompletedTrip({
    required this.id, required this.startedAt, required this.finishedAt,
    required this.fareVnd, required this.distanceMeters,
    required this.elapsedSeconds, required this.waitingSeconds,
    required this.waitFeeVnd, required this.tollVnd,
  });

  final String id;
  final DateTime startedAt, finishedAt;
  final int fareVnd, elapsedSeconds, waitingSeconds, waitFeeVnd, tollVnd;
  final double distanceMeters;

  Map<String, Object> toMap() => <String, Object>{
    'id': id,
    'started_at': startedAt.millisecondsSinceEpoch,
    'finished_at': finishedAt.millisecondsSinceEpoch,
    'fare_vnd': fareVnd,
    'distance_meters': distanceMeters,
    'elapsed_seconds': elapsedSeconds,
    'waiting_seconds': waitingSeconds,
    'wait_fee_vnd': waitFeeVnd,
    'toll_vnd': tollVnd,
  };

  factory CompletedTrip.fromMap(Map<String, Object?> data) => CompletedTrip(
    id: data['id'] as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(
      (data['started_at'] as num).toInt()),
    finishedAt: DateTime.fromMillisecondsSinceEpoch(
      (data['finished_at'] as num).toInt()),
    fareVnd: (data['fare_vnd'] as num).toInt(),
    distanceMeters: (data['distance_meters'] as num).toDouble(),
    elapsedSeconds: (data['elapsed_seconds'] as num).toInt(),
    waitingSeconds: (data['waiting_seconds'] as num).toInt(),
    waitFeeVnd: (data['wait_fee_vnd'] as num).toInt(),
    tollVnd: (data['toll_vnd'] as num).toInt(),
  );

  String get duration => formatDuration(elapsedSeconds);

  /// Không tự suy đoán địa chỉ hoặc trạng thái đã nhận tiền.
  Map<String, String> get receiptSnapshot => <String, String>{
    'id': id,
    'fare': formatVnd(fareVnd),
    'distance': formatKm(distanceMeters / 1000),
    'duration': formatDuration(elapsedSeconds),
    'waiting': formatDuration(waitingSeconds),
    'waitFee': formatVnd(waitFeeVnd) + ' (trước làm tròn tổng)',
    'toll': formatVnd(tollVnd),
    'started': formatDateTime(startedAt),
    'finished': formatDateTime(finishedAt),
    'isRecorded': 'true',
  };
}

String formatDuration(int seconds) {
  final mins = seconds ~/ 60;
  final hours = mins ~/ 60;
  final rest = mins % 60;
  final sec = seconds % 60;
  return hours > 0
      ? '${hours.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}'
      : '${mins.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)} - '
      '${two(local.day)}/${two(local.month)}/${local.year}';
}

/// Bộ lọc theo ngày hoàn thành chuyến, dựa trên giờ địa phương.
DateTime startOfPeriod(DateTime now, int days) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day)
      .subtract(Duration(days: days - 1));
}

class RevenueStats {
  const RevenueStats(this.count, this.totalFare, this.totalMeters,
      this.totalSeconds);
  final int count, totalFare, totalSeconds;
  final double totalMeters;

  static RevenueStats fromTrips(Iterable<CompletedTrip> trips) {
    var count = 0, fare = 0, seconds = 0;
    var meters = 0.0;
    for (final trip in trips) {
      count++;
      fare += trip.fareVnd;
      meters += trip.distanceMeters;
      seconds += trip.elapsedSeconds;
    }
    return RevenueStats(count, fare, meters, seconds);
  }
}
