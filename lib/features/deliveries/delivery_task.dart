import 'dart:math' as math;

import 'delivery_status.dart';

class DeliveryTask {
  const DeliveryTask({
    required this.id,
    required this.trackingNumber,
    required this.itemName,
    required this.recipientName,
    required this.recipientAddress,
    required this.status,
    required this.createdAt,
    this.senderName,
    this.senderPhone,
    this.recipientPhone,
    this.originAddress,
    this.vendor,
    this.destinationLabel,
    this.destinationLatitude,
    this.destinationLongitude,
    this.originLatitude,
    this.originLongitude,
    this.weightKg,
    this.itemType,
    this.distanceKm,
    this.proofImagePath,
    this.proofImageUrl,
    this.deliveredAt,
  });

  final int id;
  final String trackingNumber;
  final String itemName;
  final String recipientName;
  final String recipientAddress;
  final String? senderName;
  final String? senderPhone;
  final String? recipientPhone;
  final String? originAddress;
  final String? vendor;
  final String? destinationLabel;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? originLatitude;
  final double? originLongitude;
  final double? weightKg;
  final String? itemType;
  final double? distanceKm;
  final DeliveryStatus status;
  final String? proofImagePath;
  final String? proofImageUrl;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  bool get isDelivered => status == DeliveryStatus.delivered;

  factory DeliveryTask.fromMap(Map<String, dynamic> map) {
    final paket = map['paket'] is Map<String, dynamic>
        ? map['paket'] as Map<String, dynamic>
        : map['paket'] is Map
            ? Map<String, dynamic>.from(map['paket'] as Map)
            : null;
    final detail = map['detail_pengiriman'] is Map<String, dynamic>
        ? map['detail_pengiriman'] as Map<String, dynamic>
        : map['detail_pengiriman'] is Map
            ? Map<String, dynamic>.from(map['detail_pengiriman'] as Map)
            : null;
    final proof = map['bukti_pengiriman'] is Map<String, dynamic>
        ? map['bukti_pengiriman'] as Map<String, dynamic>
        : map['bukti_pengiriman'] is Map
            ? Map<String, dynamic>.from(map['bukti_pengiriman'] as Map)
            : null;

    return DeliveryTask(
      id: map['id_pengiriman'] as int,
      trackingNumber: (map['no_resi'] as String?) ?? '-',
      itemName: (paket?['nama_barang'] as String?) ?? 'Paket',
      recipientName: (map['nama_penerima'] as String?) ?? '-',
      recipientAddress: (map['alamat_tujuan'] as String?) ?? '-',
      senderName: map['nama_pengirim'] as String?,
      senderPhone: map['no_hp_pengirim'] as String?,
      recipientPhone: map['no_hp_penerima'] as String?,
      originAddress: map['alamat_asal'] as String?,
      vendor: map['vendor'] as String?,
      destinationLabel: map['alamat_tujuan'] as String?,
      destinationLatitude: (map['tujuan_lat'] as num?)?.toDouble(),
      destinationLongitude: (map['tujuan_lng'] as num?)?.toDouble(),
      originLatitude: (map['asal_lat'] as num?)?.toDouble(),
      originLongitude: (map['asal_lng'] as num?)?.toDouble(),
      weightKg: (paket?['berat'] as num?)?.toDouble(),
      itemType: paket?['jenis'] as String?,
      distanceKm: _calculateDistanceKm(
        (map['asal_lat'] as num?)?.toDouble(),
        (map['asal_lng'] as num?)?.toDouble(),
        (map['tujuan_lat'] as num?)?.toDouble(),
        (map['tujuan_lng'] as num?)?.toDouble(),
      ),
      status: DeliveryStatus.fromValue(
        (map['status'] as String?) ?? DeliveryStatus.pending.value,
      ),
      proofImagePath: proof?['path_foto'] as String?,
      proofImageUrl: proof?['path_foto'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      deliveredAt: detail?['delivered_at'] == null
          ? null
          : DateTime.parse(detail!['delivered_at'] as String),
    );
  }

  static double? _calculateDistanceKm(
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
  ) {
    if (originLat == null ||
        originLng == null ||
        destinationLat == null ||
        destinationLng == null) {
      return null;
    }

    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(destinationLat - originLat);
    final dLng = _degreesToRadians(destinationLng - originLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(originLat)) *
            math.cos(_degreesToRadians(destinationLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
