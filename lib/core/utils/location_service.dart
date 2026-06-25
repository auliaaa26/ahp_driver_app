import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../supabase/supabase_service.dart';

class LocationService {
  factory LocationService() => _instance;
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  int? _trackedDriverId;

  Future<bool> requestPermission() async {
    debugPrint('Requesting location permission...');
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Permission denied by user');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Permission denied forever');
      return false;
    }

    debugPrint('Location permission granted');
    return true;
  }

  Future<void> startTracking(int driverId) async {
    if (_positionSubscription != null && _trackedDriverId == driverId) {
      return;
    }

    stopTracking();

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      return;
    }

    _trackedDriverId = driverId;

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocation(initialPosition);
    } catch (_) {
      // Abaikan error posisi awal jika gagal, stream akan memperbarui nanti
    }

    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'Aplikasi sedang memantau lokasi pengiriman Anda.',
          notificationTitle: 'Pelacakan Lokasi Aktif',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        await _updateLocation(position);
      },
      onError: (dynamic error) {
        // Log atau abaikan error dari stream lokasi
      },
    );
  }

  Future<void> _updateLocation(Position position) async {
    final driverId = _trackedDriverId;
    if (driverId == null || !SupabaseService.isReady) return;

    try {
      await SupabaseService.client.from('driver_locations').upsert(
          {
            'driver_id': driverId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: const ['driver_id'],
        );
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _trackedDriverId = null;
  }
}
