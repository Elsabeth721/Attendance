import 'package:attendance_management_system/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance_management_system/features/controllers/superadmin_controllers/admin_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class CreateAdminScreen extends StatefulWidget {
  const CreateAdminScreen({super.key});

  @override
  State<CreateAdminScreen> createState() => _CreateAdminScreenState();
}

class _CreateAdminScreenState extends State<CreateAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final AdminController _adminController = AdminController();
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  bool _isCreating = false;
  bool _isCheckingEmail = false;
  String? _emailError;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await supabase.from("classes").select();
      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("❌ Error loading classes: $e");
    }
  }

  Future<void> _checkEmailDuplicate() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }
    
    // Validate email format first
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = "Please enter a valid email");
      return;
    }
    
    setState(() {
      _isCheckingEmail = true;
      _emailError = null;
    });
    
    try {
      // Check if email already exists in users table
      final response = await supabase
          .from("users")
          .select("id")
          .eq("email", email)
          .maybeSingle();
      
      setState(() {
        _isCheckingEmail = false;
        if (response != null) {
          _emailError = "This email is already registered. Please use a different email.";
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingEmail = false;
        _emailError = "Failed to check email availability";
      });
    }
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check email one more time before submitting
    await _checkEmailDuplicate();
    if (_emailError != null) {
      return;
    }
    
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a class",
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await _adminController.createAdmin(
        name: _usernameController.text.trim(),
        grade: _gradeController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        classId: _selectedClassId!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Admin created successfully",
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } on EmailAlreadyExistsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } on PhoneNumberFormatException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Error: ${e.toString()}",
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return "Phone number is required";
    }
    
    // Remove any non-digit characters
    final cleanedPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if phone starts with 09
    if (!cleanedPhone.startsWith('09') || !cleanedPhone.startsWith('07') ) {
      return "Phone number must start with '09' or '07' ";
    }
    
    // Check total length is 10 digits
    if (cleanedPhone.length != 10) {
      return "Phone number must be exactly 10 digits";
    }
    
    return null;
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(
        color: AppColors.textSecondary,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create Admin",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textOnPrimary,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.appBar,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),

              // Name Field
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration("Full Name", Icons.person_outline),
                validator: (val) =>
                    val == null || val.isEmpty ? "Name is required" : null,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Grade Field
              TextFormField(
                controller: _gradeController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Grade", Icons.school_outlined),
                validator: (val) =>
                    val == null || val.isEmpty ? "Grade is required" : null,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  "Email Address", 
                  Icons.email_outlined,
                  suffixIcon: _isCheckingEmail
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  // Clear error when user starts typing again
                  if (_emailError != null && value.trim().isNotEmpty) {
                    setState(() => _emailError = null);
                  }
                },
                onEditingComplete: _checkEmailDuplicate,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Email is required";
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                    return "Please enter a valid email";
                  }
                  if (_emailError != null) {
                    return _emailError;
                  }
                  return null;
                },
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration("Password", Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Password is required";
                  }
                  if (val.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputDecoration(
                  "Phone Number", 
                  Icons.phone_outlined,
                ),
                validator: _validatePhoneNumber,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
              ),
              const SizedBox(height: 16),

              // Class Dropdown
              DropdownButtonFormField<String>(
                value: _selectedClassId,
                items: _classes.map((cls) {
                  return DropdownMenuItem<String>(
                    value: cls['id'],
                    child: Text(
                      cls['name'] ?? 'Unnamed Class',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedClassId = val),
                decoration: _inputDecoration("Select Class", Icons.class_outlined),
                validator: (val) =>
                    val == null ? "Please select a class" : null,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                dropdownColor: AppColors.surface,
              ),

              const SizedBox(height: 30),

              // Create Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isCreating
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.textOnPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Creating...",
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "Create Admin",
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                height: 56,
                child: TextButton(
                  onPressed: _isCreating ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _gradeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

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