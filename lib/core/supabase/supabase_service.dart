import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseService {
  const SupabaseService._();

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  static bool get isReady => SupabaseConfig.isConfigured;

  static SupabaseClient get client {
    if (!isReady) {
      throw StateError(
        'Supabase belum dikonfigurasi. Isi SUPABASE_URL dan '
        'SUPABASE_PUBLISHABLE_KEY terlebih dahulu.',
      );
    }

    return Supabase.instance.client;
  }

  static Session? get currentSession =>
      isReady ? Supabase.instance.client.auth.currentSession : null;

  static User? get currentUser =>
      isReady ? Supabase.instance.client.auth.currentUser : null;

  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() {
    if (!isReady) {
      return Future<void>.value();
    }

    return client.auth.signOut();
  }
}
