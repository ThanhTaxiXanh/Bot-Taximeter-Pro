/// Dữ liệu Điều 6 Thông tư 38/2024; tham chiếu VBHN 74/2026.
/// Không đồng nhất "xe đến 30 chỗ" với "đến 28 chỗ KHÔNG KỂ lái xe".
enum VehicleClass {
  lightPassengerOrTruck,
  largePassengerOrTruck,
  busMotorcycleOrOther,
  trailerTanker,
  unknown,
}

enum AreaType { populated, outsidePopulated, motorway, unknown }

enum Carriageway {
  dividedOrMultilaneOneWay,
  twoWayOrSingleLaneOneWay,
  unknown,
}

abstract final class LegalBasis {
  static const speedCircular =
      '38/2024/TT-BGTVT; hợp nhất 74/2026/VBHN-TT-BXD';
  static const speedAmendment = '09/2025/TT-BXD';
  static const roadSigns = 'QCVN 41:2024/BGTVT (51/2024/TT-BGTVT)';
  static const penalties =
      '168/2024/NĐ-CP, sửa đổi bởi 238/2026/NĐ-CP';
  static const sourceSpeed =
      'https://congbao.chinhphu.vn/van-ban/thong-tu-so-38-2024-tt-bgtvt-43378.htm';
  static const sourceConsolidation =
      'https://moc.gov.vn/vn/Pages/ChiTietVanBan.aspx?vID=5060';
  static const sourceSigns =
      'https://vanban.chinhphu.vn/?docid=211908&pageid=27160';
  static const sourcePenalties =
      'https://xaydungchinhsach.chinhphu.vn/toan-van-nghi-dinh-168-2024-nd-cp-quy-dinh-xu-phat-vi-pham-hanh-chinh-ve-trat-tu-atgt-duong-bo-119241231164556785.htm';
}

class SpeedRule {
  const SpeedRule(this.vehicleClass, this.areaType, this.carriageway,
      this.limitKmh, this.legalBasis, this.articleRef, this.effectiveFrom);
  final VehicleClass vehicleClass;
  final AreaType areaType;
  final Carriageway carriageway;
  final int limitKmh;
  final String legalBasis, articleRef, effectiveFrom;
}

abstract final class SpeedRules {
  /// Bảng 1: các xe cơ giới thuộc Điều 6, trừ trường hợp Điều 7 và 8.
  /// Bảng 2 nhóm 1: chở người <=28 chỗ KHÔNG kể người lái; tải <=3,5 tấn.
  /// Nhóm 2: chở người >28 chỗ; tải >3,5 tấn trừ xi téc.
  /// Nhóm 3: xe buýt, mô tô, đầu kéo sơ-mi rơ-moóc không xi téc, v.v.
  /// Nhóm 4: xe kéo rơ-moóc, xi téc, trộn bê tông và nhóm liên quan.
  static const List<SpeedRule> all = [
    SpeedRule(VehicleClass.lightPassengerOrTruck, AreaType.populated,
        Carriageway.dividedOrMultilaneOneWay, 60,
        LegalBasis.speedCircular, 'Điều 6 khoản 1, Bảng 1', '2025-01-01'),
    SpeedRule(VehicleClass.lightPassengerOrTruck, AreaType.populated,
        Carriageway.twoWayOrSingleLaneOneWay, 50,
        LegalBasis.speedCircular, 'Điều 6 khoản 1, Bảng 1', '2025-01-01'),
    SpeedRule(VehicleClass.largePassengerOrTruck, AreaType.populated,
        Carriageway.dividedOrMultilaneOneWay, 60,
        LegalBasis.speedCircular, 'Điều 6 khoản 1, Bảng 1', '2025-01-01'),
    SpeedRule(VehicleClass.largePassengerOrTruck, AreaType.populated,
        Carriageway.twoWayOrSingleLaneOneWay, 50,
        LegalBasis.speedCircular, 'Điều 6 khoản 1, Bảng 1', '2025-01-01'),
    SpeedRule(VehicleClass.busMotorcycleOrOther, AreaType.populated,
        Carriageway.dividedOrMultilaneOneWay, 60,
        LegalBasis.speedCircular, 'Điều 6 khoản 1, Bảng 1', '2025-01-01'),
    SpeedRule(VehicleClass.busMotorcycleOrOther, AreaType.populated,
        Carriageway.twoWayOrSingleLaneOneWay, 50,
        LegalBasis.speedCircular, 'Điều 6 khoản 1, Bảng 1', '2025-01-01'),
    SpeedRule(VehicleClass.trailerTanker, AreaType.populated,
        Carriageway.dividedOrMultilaneOneWay, 60,
        LegalBasis.speedCircular, 'Điều 6 khoản 1, Bảng 1', '2025-01-01'),
    SpeedRule(VehicleClass.trailerTanker, AreaType.populated,
        Carriageway.twoWayOrSingleLaneOneWay, 50,
        LegalBasis.speedCircular, 'Điều 6 khoản 1, Bảng 1', '2025-01-01'),
    SpeedRule(VehicleClass.lightPassengerOrTruck, AreaType.outsidePopulated,
        Carriageway.dividedOrMultilaneOneWay, 90,
        LegalBasis.speedCircular, 'Điều 6 khoản 2, Bảng 2, nhóm 1', '2025-01-01'),
    SpeedRule(VehicleClass.lightPassengerOrTruck, AreaType.outsidePopulated,
        Carriageway.twoWayOrSingleLaneOneWay, 80,
        LegalBasis.speedCircular, 'Điều 6 khoản 2, Bảng 2, nhóm 1', '2025-01-01'),
    SpeedRule(VehicleClass.largePassengerOrTruck, AreaType.outsidePopulated,
        Carriageway.dividedOrMultilaneOneWay, 80,
        LegalBasis.speedCircular, 'Điều 6 khoản 2, Bảng 2, nhóm 2', '2025-01-01'),
    SpeedRule(VehicleClass.largePassengerOrTruck, AreaType.outsidePopulated,
        Carriageway.twoWayOrSingleLaneOneWay, 70,
        LegalBasis.speedCircular, 'Điều 6 khoản 2, Bảng 2, nhóm 2', '2025-01-01'),
    SpeedRule(VehicleClass.busMotorcycleOrOther, AreaType.outsidePopulated,
        Carriageway.dividedOrMultilaneOneWay, 70,
        LegalBasis.speedCircular, 'Điều 6 khoản 2, Bảng 2, nhóm 3', '2025-01-01'),
    SpeedRule(VehicleClass.busMotorcycleOrOther, AreaType.outsidePopulated,
        Carriageway.twoWayOrSingleLaneOneWay, 60,
        LegalBasis.speedCircular, 'Điều 6 khoản 2, Bảng 2, nhóm 3', '2025-01-01'),
    SpeedRule(VehicleClass.trailerTanker, AreaType.outsidePopulated,
        Carriageway.dividedOrMultilaneOneWay, 60,
        LegalBasis.speedCircular, 'Điều 6 khoản 2, Bảng 2, nhóm 4', '2025-01-01'),
    SpeedRule(VehicleClass.trailerTanker, AreaType.outsidePopulated,
        Carriageway.twoWayOrSingleLaneOneWay, 50,
        LegalBasis.speedCircular, 'Điều 6 khoản 2, Bảng 2, nhóm 4', '2025-01-01'),
  ];
  /// Điều 9: khung chung cao tốc, KHÔNG dùng làm biển của từng tuyến.
  static const motorwayCeilingKmh = 120;
  static const motorwayGeneralFloorKmh = 60;

  static SpeedRule? find(VehicleClass vehicle, AreaType area,
      Carriageway carriageway) {
    for (final rule in all) {
      if (rule.vehicleClass == vehicle && rule.areaType == area &&
          rule.carriageway == carriageway) return rule;
    }
    return null;
  }
}
