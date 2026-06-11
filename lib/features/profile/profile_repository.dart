import '../../core/supabase/supabase_service.dart';
import 'driver_profile.dart';

class ProfileRepository {
  const ProfileRepository();

  static const String _table = 'profiles';

  Future<DriverProfile> fetchProfileByEmail(String email) async {
    final response = await SupabaseService.client
        .from(_table)
        .select()
        .eq('email', email)
        .single();

    return DriverProfile.fromMap(Map<String, dynamic>.from(response));
  }

  Future<DriverProfile> fetchDriverProfileByEmail(String email) async {
    final profile = await fetchProfileByEmail(email);
    final role = profile.role?.trim().toLowerCase();

    if (role != 'driver') {
      throw StateError('Akun ini bukan driver.');
    }

    return profile;
  }
}
