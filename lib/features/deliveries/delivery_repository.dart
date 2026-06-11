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
  static const String _proofBucket = 'delivery-proofs';

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
    final String extension = file.path.split('.').last.toLowerCase();
    final String filePath =
        '${driver.id}/${task.id}-${DateTime.now().millisecondsSinceEpoch}.$extension';

    await SupabaseService.client.storage.from(_proofBucket).upload(
          filePath,
          file,
          fileOptions: FileOptions(upsert: true),
        );

    final String publicUrl =
        SupabaseService.client.storage.from(_proofBucket).getPublicUrl(filePath);
    final String now = DateTime.now().toIso8601String();

    final existingProof = await SupabaseService.client
        .from(_proofTable)
        .select('id_bukti')
        .eq('id_pengiriman', task.id)
        .maybeSingle();

    if (existingProof == null) {
      await SupabaseService.client.from(_proofTable).insert(<String, dynamic>{
        'id_pengiriman': task.id,
        'path_foto': publicUrl,
        'waktu_upload': now,
      });
    } else {
      await SupabaseService.client.from(_proofTable).update(<String, dynamic>{
        'path_foto': publicUrl,
        'waktu_upload': now,
      }).eq('id_bukti', existingProof['id_bukti']);
    }

    await SupabaseService.client.from(_shipmentTable).update(<String, dynamic>{
      'status': DeliveryStatus.delivered.value,
    }).eq('id_pengiriman', task.id);

    await _upsertDetail(
      task.id,
      DeliveryStatus.delivered,
      now,
      goodsReceiptUrl: publicUrl,
    );

    await _insertTrackingEvent(
      taskId: task.id,
      status: DeliveryStatus.delivered,
      timestamp: now,
      location: task.destinationLabel ?? task.recipientAddress,
      description: 'Bukti pengiriman diunggah oleh driver ${driver.name}',
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
    final proof = await SupabaseService.client
        .from(_proofTable)
        .select()
        .eq('id_pengiriman', shipmentId)
        .order('waktu_upload', ascending: false)
        .limit(1)
        .maybeSingle();

    shipment['paket'] = paket == null ? null : Map<String, dynamic>.from(paket);
    shipment['detail_pengiriman'] =
        detail == null ? null : Map<String, dynamic>.from(detail);
    shipment['bukti_pengiriman'] =
        proof == null ? null : Map<String, dynamic>.from(proof);

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
}
