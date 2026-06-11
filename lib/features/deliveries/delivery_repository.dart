import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../profile/driver_profile.dart';
import 'delivery_status.dart';
import 'delivery_task.dart';

class DeliveryRepository {
  const DeliveryRepository();

  static const String _shipmentTable = 'pengiriman';
  static const String _packageTable = 'paket';
  static const String _detailTable = 'detail_pengiriman';
  static const String _proofTable = 'bukti_pengiriman';
  static const String _trackingTable = 'tracking_pengiriman';
  static const String _proofBucket = 'bukti_pengiriman';
  static const Duration _proofUrlTtl = Duration(days: 7);
  static const int _maxProofPhotos = 3;

  Future<DeliveryTask?> fetchCurrentTask(DriverProfile driver) async {
    final response = await SupabaseService.client
        .from(_shipmentTable)
        .select()
        .eq('driver', driver.name)
        .order('created_at', ascending: false)
        .limit(20);

    if (response.isEmpty) {
      return null;
    }

    for (final item in response) {
      final taskMap = await _enrichShipment(Map<String, dynamic>.from(item));
      final task = DeliveryTask.fromMap(taskMap);

      if (task.status != DeliveryStatus.completed &&
          task.status != DeliveryStatus.delivered) {
        return task;
      }
    }

    return null;
  }

  Future<List<DeliveryTask>> fetchHistory(DriverProfile driver) async {
    final response = await SupabaseService.client
        .from(_shipmentTable)
        .select()
        .eq('driver', driver.name)
        .order('created_at', ascending: false);

    final List<DeliveryTask> tasks = <DeliveryTask>[];
    for (final item in response) {
      final taskMap = await _enrichShipment(Map<String, dynamic>.from(item));
      final task = DeliveryTask.fromMap(taskMap);
      if (task.status == DeliveryStatus.completed ||
          task.status == DeliveryStatus.delivered) {
        tasks.add(task);
      }
    }
    return tasks;
  }

  Future<void> updateStatus({
    required DeliveryTask task,
    required DriverProfile driver,
    required DeliveryStatus status,
  }) async {
    final now = DateTime.now().toIso8601String();

    await SupabaseService.client.from(_shipmentTable).update(<String, dynamic>{
      'status': status.value,
    }).eq('id_pengiriman', task.id);

    await _upsertDetail(task.id, status, now);

    await _insertTrackingEvent(
      taskId: task.id,
      status: status,
      timestamp: now,
      location: task.destinationLabel ?? task.recipientAddress,
      description: 'Status diperbarui oleh driver ${driver.name}',
    );
  }

  Future<void> uploadProof({
    required DeliveryTask task,
    required DriverProfile driver,
    required File file,
  }) async {
    if (task.proofCount >= _maxProofPhotos) {
      throw StateError('Maksimal 3 foto bukti pengiriman.');
    }

    final String extension = file.path.split('.').last.toLowerCase();
    final String filePath =
        '${driver.id}/${task.id}-${DateTime.now().millisecondsSinceEpoch}.$extension';

    await SupabaseService.client.storage.from(_proofBucket).upload(
          filePath,
          file,
          fileOptions: FileOptions(upsert: true),
        );

    final String now = DateTime.now().toIso8601String();
    await SupabaseService.client.from(_proofTable).insert(<String, dynamic>{
      'id_pengiriman': task.id,
      'path_foto': filePath,
      'waktu_upload': now,
    });

    await _insertTrackingEvent(
      taskId: task.id,
      status: task.status,
      timestamp: now,
      location: task.destinationLabel ?? task.recipientAddress,
      description: 'Bukti pengiriman diunggah oleh driver ${driver.name}',
    );

    await _upsertDetail(
      task.id,
      task.status,
      now,
      goodsReceiptUrl: filePath,
    );
  }

  Future<Map<String, dynamic>> _enrichShipment(Map<String, dynamic> shipment) async {
    final int shipmentId = shipment['id_pengiriman'] as int;
    final int? packageId = shipment['id_paket'] as int?;

    final paket = packageId == null
        ? null
        : await SupabaseService.client
            .from(_packageTable)
            .select()
            .eq('id_paket', packageId)
            .maybeSingle();
    final detail = await SupabaseService.client
        .from(_detailTable)
        .select()
        .eq('id_pengiriman', shipmentId)
        .maybeSingle();
    final proofRows = await SupabaseService.client
        .from(_proofTable)
        .select()
        .eq('id_pengiriman', shipmentId)
        .order('waktu_upload', ascending: false)
        .limit(_maxProofPhotos);

    shipment['paket'] = paket == null ? null : Map<String, dynamic>.from(paket);
    shipment['detail_pengiriman'] =
        detail == null ? null : Map<String, dynamic>.from(detail);
    if (proofRows.isEmpty) {
      shipment['bukti_pengiriman'] = null;
    } else {
      final proofMaps = <Map<String, dynamic>>[];
      for (final item in proofRows) {
        final proofMap = Map<String, dynamic>.from(item);
        final proofReference = proofMap['path_foto'] as String?;
        final resolvedProofUrl = await _resolveProofUrl(proofReference);
        if (resolvedProofUrl != null) {
          proofMap['proof_image_url'] = resolvedProofUrl;
        }
        proofMaps.add(proofMap);
      }
      shipment['bukti_pengiriman'] = proofMaps;
    }

    return shipment;
  }

  Future<void> _upsertDetail(
    int shipmentId,
    DeliveryStatus status,
    String timestamp, {
    String? goodsReceiptUrl,
  }) async {
    final existingDetail = await SupabaseService.client
        .from(_detailTable)
        .select('id_detail_pengiriman')
        .eq('id_pengiriman', shipmentId)
        .maybeSingle();

    final Map<String, dynamic> payload = <String, dynamic>{
      'id_pengiriman': shipmentId,
      'updated_at': timestamp,
      if (status == DeliveryStatus.pending) 'picked_up_at': timestamp,
      if (status == DeliveryStatus.inDelivery) 'in_transit_at': timestamp,
      if (status == DeliveryStatus.completed) 'delivered_at': timestamp,
      if (status == DeliveryStatus.delivered) 'delivered_at': timestamp,
      if (goodsReceiptUrl != null) 'goods_receipt_url': goodsReceiptUrl,
    };

    if (existingDetail == null) {
      await SupabaseService.client.from(_detailTable).insert(<String, dynamic>{
        ...payload,
        'created_at': timestamp,
        'is_paid': false,
      });
    } else {
      await SupabaseService.client.from(_detailTable).update(payload).eq(
            'id_detail_pengiriman',
            existingDetail['id_detail_pengiriman'],
          );
    }
  }

  Future<void> _insertTrackingEvent({
    required int taskId,
    required DeliveryStatus status,
    required String timestamp,
    required String description,
    String? location,
  }) async {
    PostgrestException? lastConstraintError;

    for (final trackingStatus in status.trackingFallbackValues) {
      try {
        await SupabaseService.client.from(_trackingTable).insert(<String, dynamic>{
          'id_pengiriman': taskId,
          'status': trackingStatus,
          'waktu': timestamp,
          'lokasi': location,
          'keterangan': description,
          'created_at': timestamp,
        });
        return;
      } on PostgrestException catch (error) {
        if (error.code == '23514') {
          lastConstraintError = error;
          continue;
        }

        rethrow;
      }
    }

    if (lastConstraintError != null) {
      // Do not block status/proof updates when tracking uses a stricter legacy enum.
      return;
    }
  }

  Future<String?> _resolveProofUrl(String? proofReference) async {
    if (proofReference == null || proofReference.trim().isEmpty) {
      return null;
    }

    final reference = proofReference.trim();
    final path = _extractStoragePath(reference);

    if (path == null) {
      return reference;
    }

    try {
      return await SupabaseService.client.storage
          .from(_proofBucket)
          .createSignedUrl(path, _proofUrlTtl.inSeconds);
    } catch (_) {
      return reference;
    }
  }

  String? _extractStoragePath(String reference) {
    if (!reference.startsWith('http')) {
      return reference;
    }

    final uri = Uri.tryParse(reference);
    if (uri == null) {
      return null;
    }

    final marker = '/$_proofBucket/';
    final rawPath = uri.path;
    final index = rawPath.indexOf(marker);
    if (index == -1) {
      return null;
    }

    return Uri.decodeComponent(rawPath.substring(index + marker.length));
  }
}
