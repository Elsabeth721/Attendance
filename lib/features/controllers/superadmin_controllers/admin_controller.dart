import 'package:supabase_flutter/supabase_flutter.dart';

class AdminController {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create an Admin (superadmin will call this)
  Future<void> createAdmin({
    required String name,
    required String grade,
    required String phoneNumber,
    required String password,
    required String email,
    required String classId, // Admins must belong to a class
  }) async {
    try {
      final response = await _client.from('users').insert({
        'username': name,
        'grade': int.parse(grade),
        'phone_number': phoneNumber,
        'password': password, // ⚠️ Plaintext (not secure)
        'email': email,
        'role': 'admin',
        'class_id': classId,
      });

      print("✅ Admin created: $response");
    } catch (e) {
      print("❌ Error creating admin: $e");
      rethrow;
    }
  }

  /// Create a Superadmin (only once or via secure backend)
  Future<void> createSuperAdmin({
    required String name,
    required String grade,
    required String phoneNumber,
    required String password,
    required String email,
  }) async {
    try {
      final response = await _client.from('users').insert({
        'username': name,
        'grade': int.parse(grade),
        'phone_number': phoneNumber,
        'password': password,
        'email': email,
        'role': 'superadmin',
        'class_id': null, // Superadmins don’t have class_id
      });

      print("✅ Superadmin created: $response");
    } catch (e) {
      print("❌ Error creating superadmin: $e");
      rethrow;
    }
  }

  /// List all admins (optional filter by class)
  Future<List<Map<String, dynamic>>> listAdmins({String? classId}) async {
    try {
      final query = _client
          .from('users')
          .select()
          .eq('role', 'admin');

      if (classId != null) {
        query.eq('class_id', classId);
      }

      final response = await query;
      print("✅ Admins fetched: $response");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ Error listing admins: $e");
      return [];
    }
  }
}
