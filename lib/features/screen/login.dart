import 'dart:async';

import 'package:attendance_management_system/core/constants.dart';
import 'package:attendance_management_system/features/screen/admin_screen/home.dart';
import 'package:attendance_management_system/features/screen/superadmin_screen/home.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  // Check internet connection using built-in method
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Show error dialog in Amharic
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'እሺ',
              style: GoogleFonts.dmSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show success dialog
  void _showSuccessDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _login() async {
    // Validate fields
    final email = _usernameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog(
        'ባዶ ሳጥን',
        'እባክዎ ኢሜል እና የይለፍ ቃልዎን ያስገቡ',
      );
      return;
    }

    // Email format validation
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog(
        'የተሳሳተ ኢሜል',
        'እባክዎ ትክክለኛ ኢሜል አድራሻ ያስገቡ',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check internet connection first
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        _showErrorDialog(
          'ኢንተርኔት ግንኙነት',
          'ኢንተርኔት ኮኔክሽን ያስፈልጋል። እባክዎ ግንኙነትዎን ያረጋግጡ',
        );
        return;
      }

      // Check admin in public.users table first
      final admin = await supabase
          .from('users')
          .select()
          .eq('email', email)
          .eq('password', password)
          .eq('role', 'admin')
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (admin != null) {
        final adminName = admin['username'] as String? ?? 'Admin';
        debugPrint("✅ Admin logged in: ${admin['username']}");
        _showSuccessDialog('በተሳካ ሁኔታ ገብተዋል!');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminHomePage(adminName: adminName, adminEmail: email),
          ),
        );
        return;
      }

      // Try Supabase Auth login (superadmin)
      final authResponse = await supabase.auth
          .signInWithPassword(
            email: email,
            password: password,
          )
          .timeout(const Duration(seconds: 10));

      final authUser = authResponse.user;
      if (authUser != null) {
        final record = await supabase
            .from('users')
            .select()
            .eq('auth_id', authUser.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));

        final role = record?['role'] ?? 'superadmin';
        debugPrint("✅ Supabase Auth user logged in: $role");

        if (role == 'superadmin') {
          _showSuccessDialog('በተሳካ ሁኔታ ገብተዋል!');
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SuperAdminHomePage()),
          );
          return;
        }
      }

      // If nothing matched - invalid credentials
      _showErrorDialog(
        'የተሳሳተ መረጃ',
        'የተሳሳተ ኢሜል ወይም የይለፍ ቃል አስገብተዋል። እባክዎ እንደገና ይሞክሩ',
      );

    } on TimeoutException {
      _showErrorDialog(
        'ጊዜ አልፎበታል',
        'መግቢያው ረጅም ጊዜ ወስዷል። እባክዎ እንደገና ይሞክሩ',
      );
    } on AuthException catch (e) {
      // Handle specific Supabase auth errors
      if (e.message.contains('Invalid login credentials')) {
        _showErrorDialog(
          'የተሳሳተ መረጃ',
          'የተሳሳተ ኢሜል ወይም የይለፍ ቃል አስገብተዋል። እባክዎ እንደገና ይሞክሩ',
        );
      } else if (e.message.contains('Email not confirmed')) {
        _showErrorDialog(
          'ኢሜል አልተረጋገጠም',
          'እባክዎ ኢሜልዎን ያረጋግጡ ከመግባትዎ በፊት',
        );
      } else {
        _showErrorDialog(
          'ስህተት',
          'የማላውቀው ስህተት ተከስቷል። እባክዎ እንደገና ይሞክሩ',
        );
      }
    } on PostgrestException catch (e) {
      _showErrorDialog(
        'የዳታቤዝ ስህተት',
        'ከሰርቨር ጋር ችግር አጋጥሞታል። እባክዎ ቆይተው እንደገና ይሞክሩ',
      );
      debugPrint("Database error: ${e.message}");
    } catch (e, stack) {
      debugPrint("❌ Unexpected error during login: $e");
      debugPrint("📌 Stack: $stack");
      _showErrorDialog(
        'ስህተት',
        'ያልተጠበቀ ስህተት ተከስቷል። እባክዎ እንደገና ይሞክሩ',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildScriptureContainer(),
                const SizedBox(height: 40),
                Column(
                  children: [
                    Text(
                      'Login',
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome back, please sign in',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(fontFamily: 'DMSans'),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(fontFamily: 'DMSans'),
                        prefixIcon:
                            const Icon(Icons.person, color: AppColors.primary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontFamily: 'DMSans'),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(fontFamily: 'DMSans'),
                        prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: _isLoading
                          ? ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary.withOpacity(0.5),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'በመግባት ላይ...',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonPrimary,
                                foregroundColor: AppColors.textOnPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                'Login',
                                style: GoogleFonts.dmSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScriptureContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.buttonPrimary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '«ታገለግሉት ዘንድ ፥ አገልጋዮቹም ትሆኑ ዘንድ መርጧችኋል»',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '2ዜና 29፥11',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}