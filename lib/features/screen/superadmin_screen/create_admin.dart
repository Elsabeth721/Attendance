import 'package:attendance_management_system/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance_management_system/features/controllers/superadmin_controllers/admin_controller.dart';
import 'package:google_fonts/google_fonts.dart';

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

  List<Map<String, dynamic>> _classes = [];
  String? _selectedClassId;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await Supabase.instance.client.from("classes").select();
      setState(() {
        _classes = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("❌ Error loading classes: $e");
    }
  }

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) return;
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Error: $e",
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmSans(
        color: AppColors.textSecondary,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary),
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
              // Header
             
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
                decoration: _inputDecoration("Email Address", Icons.email_outlined),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return "Email is required";
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                    return "Please enter a valid email";
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
                obscureText: true,
                decoration: _inputDecoration("Password", Icons.lock_outline),
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
                decoration: _inputDecoration("Phone Number", Icons.phone_outlined),
                validator: (val) =>
                    val == null || val.isEmpty ? "Phone number is required" : null,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
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
                            SizedBox(
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