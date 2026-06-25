class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://wbckqoynywrfubfxorkf.supabase.co';
  
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndiY2txb3lueXdyZnViZnhvcmtmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3NjQwMDcsImV4cCI6MjA5NDM0MDAwN30.Q9K6_1yebvsgsPHCYrHPnZY_hjoeF9kjuvXdXr0RMu8'; 

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}