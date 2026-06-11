import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import 'driver_profile.dart';

class ProfileRepository {
  const ProfileRepository();

  static const String _table = 'profiles';
  static const String _avatarBucket = 'profile_avatar';
  static const Duration _avatarUrlTtl = Duration(days: 7);

  Future<DriverProfile> fetchProfileByEmail(String email) async {
    final response = await SupabaseService.client
        .from(_table)
        .select()
        .eq('email', email)
        .single();

    final profileMap = Map<String, dynamic>.from(response);
    final avatarReference = profileMap['avatar_url'] as String?;
    final resolvedAvatarUrl = await _resolveAvatarUrl(avatarReference);

    if (resolvedAvatarUrl != null) {
      profileMap['avatar_url'] = resolvedAvatarUrl;
    }

    return DriverProfile.fromMap(profileMap);
  }

  Future<DriverProfile> fetchDriverProfileByEmail(String email) async {
    final profile = await fetchProfileByEmail(email);
    final role = profile.role?.trim().toLowerCase();

    if (role != 'driver') {
      throw StateError('Akun ini bukan driver.');
    }

    return profile;
  }

  Future<DriverProfile> uploadAvatar({
    required DriverProfile profile,
    required File file,
  }) async {
    final String extension = file.path.split('.').last.toLowerCase();
    final String basePath = '${profile.id}/avatar';
    final String filePath = '$basePath.$extension';

    await _removeLegacyAvatars(
      profile: profile,
      currentExtension: extension,
    );

    await SupabaseService.client.storage.from(_avatarBucket).upload(
          filePath,
          file,
          fileOptions: FileOptions(upsert: true),
        );

    final String signedUrl = await SupabaseService.client.storage
        .from(_avatarBucket)
        .createSignedUrl(
          filePath,
          _avatarUrlTtl.inSeconds,
        );

    final response = await SupabaseService.client
        .from(_table)
        .update(<String, dynamic>{
          // Store the storage path so we can refresh the signed URL later.
          'avatar_url': filePath,
        })
        .eq('id', profile.id)
        .select()
        .single();

    final profileMap = Map<String, dynamic>.from(response)
      ..['avatar_url'] = signedUrl;

    return DriverProfile.fromMap(profileMap);
  }

  Future<void> _removeLegacyAvatars({
    required DriverProfile profile,
    required String currentExtension,
  }) async {
    final folder = profile.id.toString();
    final existingFiles =
        await SupabaseService.client.storage.from(_avatarBucket).list(
              path: folder,
            );

    final filesToRemove = existingFiles
        .where((item) => item.name.startsWith('avatar.'))
        .where((item) => item.name != 'avatar.$currentExtension')
        .map((item) => '$folder/${item.name}')
        .toList();

    if (filesToRemove.isNotEmpty) {
      await SupabaseService.client.storage
          .from(_avatarBucket)
          .remove(filesToRemove);
    }
  }

  Future<String?> _resolveAvatarUrl(String? avatarReference) async {
    if (avatarReference == null || avatarReference.trim().isEmpty) {
      return null;
    }

    final reference = avatarReference.trim();
    final path = _extractStoragePath(reference);

    if (path == null) {
      return reference;
    }

    try {
      return await SupabaseService.client.storage.from(_avatarBucket).createSignedUrl(
            path,
            _avatarUrlTtl.inSeconds,
          );
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

    final marker = '/$_avatarBucket/';
    final rawPath = uri.path;
    final index = rawPath.indexOf(marker);

    if (index == -1) {
      return null;
    }

    return Uri.decodeComponent(rawPath.substring(index + marker.length));
  }
}
