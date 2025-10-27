import 'package:supabase_flutter/supabase_flutter.dart';

class ClassController {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createClass(String name) async {
    try {
      final response = await _client
          .from('classes')
          .insert({'name': name})
          .select(); // return inserted row(s)

      // Log response for debugging
      print("✅ Class inserted: $response");
    } on PostgrestException catch (e) {
      // Catches database errors
      print("❌ PostgrestException: ${e.message}");
      throw Exception(e.message);
    } catch (e, stack) {
      // Catches any other error
      print("❌ Unknown error: $e");
      print(stack);
      rethrow;
    }
  }
}
