/// Số liệu minh họa theo ảnh thiết kế, tuyệt đối không phải doanh thu thật.
class MockRevenuePeriod {
  const MockRevenuePeriod({
    required this.label, required this.revenue,
    required this.trips, required this.distance, required this.hours,
    required this.revenueDelta, required this.tripDelta,
    required this.distanceDelta, required this.hoursDelta,
  });
  final String label;
  final String revenue;
  final String trips;
  final String distance;
  final String hours;
  final String revenueDelta;
  final String tripDelta;
  final String distanceDelta;
  final String hoursDelta;
}

const mockPeriods = <MockRevenuePeriod>[
  MockRevenuePeriod(
    label: 'Hôm nay', revenue: '1.284.000 đ', trips: '14',
    distance: '83,4 km', hours: '6 giờ 42 phút',
    revenueDelta: '▲ +12,6% so với hôm qua',
    tripDelta: '▲ +3', distanceDelta: '▲ +9,8 km',
    hoursDelta: '▲ +28 phút',
  ),
  MockRevenuePeriod(
    label: '7 ngày', revenue: '8.436.000 đ', trips: '95',
    distance: '567,9 km', hours: '47 giờ 10 phút',
    revenueDelta: '▲ +8,2% (mẫu)', tripDelta: '▲ +11',
    distanceDelta: '▲ +34 km', hoursDelta: '▲ +3 giờ',
  ),
  MockRevenuePeriod(
    label: '30 ngày', revenue: '31.420.000 đ', trips: '365',
    distance: '2.154,0 km', hours: '194 giờ 15 phút',
    revenueDelta: '▲ +6,4% (mẫu)', tripDelta: '▲ +23',
    distanceDelta: '▲ +118 km', hoursDelta: '▲ +9 giờ',
  ),
];

const mockDailyRevenue = <int>[
  980000, 1120000, 1045000, 1230000, 1365000, 1412000, 1284000,
];
const mockDailyLabels = <String>[
  'T2\n20/01', 'T3\n21/01', 'T4\n22/01', 'T5\n23/01',
  'T6\n24/01', 'T7\n25/01', 'CN\n26/01',
];
const mockDailyValueLabels = <String>[
  '980k', '1.120k', '1.045k', '1.230k', '1.365k', '1.412k', '1.284k',
];

class MockHistoryTrip {
  const MockHistoryTrip({
    required this.id, required this.time, required this.pickup,
    required this.dropoff, required this.payment, required this.fare,
    required this.distance, required this.dayOffset,
  });
  final String id;
  final String time;
  final String pickup;
  final String dropoff;
  final String payment;
  final String fare;
  final String distance;
  final int dayOffset;

  Map<String, String> get receiptSnapshot => <String, String>{
    'fare': fare,
    'distance': distance,
    'duration': '00:34 (mẫu)',
    'waiting': '02:10 (mẫu)',
    'toll': '0 đ',
    'id': id,
    'pickup': pickup,
    'dropoff': dropoff,
    'payment': payment,
  };
}

const mockHistoryTrips = <MockHistoryTrip>[
  MockHistoryTrip(
    id: 'TTX-250126-0147', dayOffset: 0, time: '09:18 - 09:52',
    pickup: '186 Nguyễn Thị Lưu, Bắc Giang',
    dropoff: 'Khách sạn Mường Thanh Luxury Bắc Giang',
    payment: 'Thẻ (VNPay)', fare: '112.000 đ', distance: '8,4 km',
  ),
  MockHistoryTrip(
    id: 'TTX-250126-0146', dayOffset: 0, time: '08:06 - 08:37',
    pickup: 'Đức Thảo Game Center',
    dropoff: 'KhắcLANDS Gaming Center',
    payment: 'Tiền mặt', fare: '76.000 đ', distance: '5,8 km',
  ),
  MockHistoryTrip(
    id: 'TTX-250126-0145', dayOffset: 0, time: '07:12 - 07:48',
    pickup: 'ACBoutique244',
    dropoff: 'BOSSAM BBQ - 186 Nguyễn Thị Lưu',
    payment: 'Ví điện tử (MoMo)', fare: '98.000 đ', distance: '7,2 km',
  ),
  MockHistoryTrip(
    id: 'TTX-250125-0139', dayOffset: 1, time: '16:20 - 16:58',
    pickup: 'Bến xe Bắc Giang',
    dropoff: 'Khách sạn Mường Thanh',
    payment: 'Tiền mặt', fare: '104.000 đ', distance: '8,0 km',
  ),
  MockHistoryTrip(
    id: 'TTX-250123-0103', dayOffset: 3, time: '11:10 - 11:49',
    pickup: 'Bệnh viện Đa khoa tỉnh Bắc Giang',
    dropoff: 'Đường Nguyễn Văn Cừ',
    payment: 'Thẻ (VNPay)', fare: '86.000 đ', distance: '6,9 km',
  ),
  MockHistoryTrip(
    id: 'TTX-250110-0044', dayOffset: 16, time: '14:05 - 14:42',
    pickup: 'Nhà hàng Hương Quê',
    dropoff: 'Bến xe Bắc Giang',
    payment: 'Tiền mặt', fare: '91.000 đ', distance: '7,1 km',
  ),
];
