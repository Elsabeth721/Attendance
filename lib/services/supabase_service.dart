import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://doauykteqlpnxzcjkkht.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvYXV5a3RlcWxwbnh6Y2pra2h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzNjU1MDMsImV4cCI6MjA3MTk0MTUwM30.3EruISh1N_xWZ_ObPUoMTg6WgEdDkoea5KZAk_dBT_c',
    );
  }
}
