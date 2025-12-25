// import 'package:supabase_flutter/supabase_flutter.dart';

// class AdminController {
//   final SupabaseClient _client = Supabase.instance.client;

//   /// Create an Admin (superadmin will call this)
//   Future<void> createAdmin({
//     required String name,
//     required String grade,
//     required String phoneNumber,
//     required String password,
//     required String email,
//     required String classId, // Admins must belong to a class
//   }) async {
//     try {
//       final response = await _client.from('users').insert({
//         'username': name,
//         'grade': int.parse(grade),
//         'phone_number': phoneNumber,
//         'password': password, // ⚠️ Plaintext (not secure)
//         'email': email,
//         'role': 'admin',
//         'class_id': classId,
//       });

//       print("✅ Admin created: $response");
//     } catch (e) {
//       print("❌ Error creating admin: $e");
//       rethrow;
//     }
//   }
import 'package:supabase_flutter/supabase_flutter.dart';

// Custom exceptions for better error handling
class EmailAlreadyExistsException implements Exception {
  final String message;
  
  EmailAlreadyExistsException(this.message);
  
  @override
  String toString() => message;
}

class PhoneNumberFormatException implements Exception {
  final String message;
  
  PhoneNumberFormatException(this.message);
  
  @override
  String toString() => message;
}

class AdminController {
  final SupabaseClient _client = Supabase.instance.client;

  /// Check if email already exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print("❌ Error checking email: $e");
      return false;
    }
  }

  /// Validate phone number format (should start with 09 and be 10 digits)
  bool validatePhoneNumber(String phoneNumber) {
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return cleanedPhone.startsWith('09') && cleanedPhone.length == 10;
  }

  /// Clean phone number (remove non-digit characters)
  String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Create an Admin (superadmin will call this)
  Future<void> createAdmin({
    required String name,
    required String grade,
    required String phoneNumber,
    required String password,
    required String email,
    required String classId,
  }) async {
    try {
      // Check if email already exists
      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        throw EmailAlreadyExistsException(
          "This email address is already registered. Please use a different email."
        );
      }

      // Validate phone number format
      final cleanedPhone = cleanPhoneNumber(phoneNumber);
      if (!validatePhoneNumber(phoneNumber)) {
        throw PhoneNumberFormatException(
          "Phone number must start with '09' and be exactly 10 digits long. Example: 0912345678"
        );
      }

      // Validate grade is a number
      int gradeInt;
      try {
        gradeInt = int.parse(grade);
      } catch (e) {
        throw FormatException("Grade must be a valid number");
      }

      // Create admin user
      final response = await _client.from('users').insert({
        'username': name,
        'grade': gradeInt,
        'phone_number': cleanedPhone,
        'password': password, // ⚠️ Plaintext - consider using Supabase Auth
        'email': email,
        'role': 'admin',
        'class_id': classId,
        'created_at': DateTime.now().toIso8601String(),
      });

      print("✅ Admin created: $response");
    } on EmailAlreadyExistsException catch (e) {
      print("❌ Email already exists: ${e.message}");
      rethrow;
    } on PhoneNumberFormatException catch (e) {
      print("❌ Invalid phone number: ${e.message}");
      rethrow;
    } on FormatException catch (e) {
      print("❌ Invalid grade: ${e.message}");
      rethrow;
    } on PostgrestException catch (e) {
      print("❌ Database error creating admin: $e");
      
      // Check for duplicate email error from database
      if (e.message.contains('duplicate key') || 
          e.message.contains('already exists') || 
          e.message.contains('unique')) {
        throw EmailAlreadyExistsException(
          "This email address is already registered. Please use a different email."
        );
      }
      
      rethrow;
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
