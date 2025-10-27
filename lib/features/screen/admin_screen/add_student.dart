import 'package:attendance_management_system/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AddStudentPage extends StatefulWidget {
  final String adminEmail;
  const AddStudentPage({super.key, required this.adminEmail});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();

  String? _selectedSex;
  String? _adminClassId;

  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminClass();
  }

  Future<void> _loadAdminClass() async {
    try {
      final response = await supabase
          .from('users')
          .select('class_id')
          .eq('email', widget.adminEmail)
          .maybeSingle();

      if (response == null || response['class_id'] == null) {
        throw Exception("Admin's class not found");
      }

      setState(() {
        _adminClassId = response['class_id'] as String;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint("❌ Error fetching admin class: $e");
      debugPrint("📌 Stack: $stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading admin class: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

 Future<void> _saveStudent() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final adminRecord = await supabase
        .from('users')
        .select('id ,class_id')
        .eq('email', widget.adminEmail)
        .maybeSingle();

    if (adminRecord == null || adminRecord['class_id'] == null) {
      throw Exception("Admin's class not found.");
    }

    final classId = adminRecord['class_id'];

    await supabase.from('students').insert({
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone_number1': _phone1Controller.text.trim(),
      'phone_number2':
          _phone2Controller.text.trim().isEmpty ? null : _phone2Controller.text.trim(),
      'sex': _selectedSex,
      'grade_id': classId,
      'created_by': adminRecord['id'], 
      'created_at': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Student added successfully!")),
    );

    Navigator.pop(context);

  } catch (e, stack) {
    debugPrint("❌ Error adding student: $e");
    debugPrint("📌 Stack trace: $stack");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error adding student: $e")),
    );
  }
}

  Future<String?> _getAdminId() async {
    final response = await supabase
        .from('users')
        .select('id')
        .eq('email', widget.adminEmail)
        .maybeSingle();
    return response?['id'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Text(
          "Add Student",
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _firstNameController,
                        decoration: _inputDecoration("First Name"),
                        validator: (value) =>
                            value!.isEmpty ? "Enter first name" : null,
                      ),
                      const SizedBox(height: 15),

                      // Last Name
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _lastNameController,
                        decoration: _inputDecoration("Last Name"),
                        validator: (value) =>
                            value!.isEmpty ? "Enter last name" : null,
                      ),
                      const SizedBox(height: 15),

                      // Phone 1
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _phone1Controller,
                        decoration: _inputDecoration("Phone Number 1"),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value!.isEmpty ? "Enter phone number" : null,
                      ),
                      const SizedBox(height: 15),

                      // Phone 2
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _phone2Controller,
                        decoration: _inputDecoration("Phone Number 2 (Optional)"),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: _selectedSex,
                        items: ["Male", "Female"]
                            .map((sex) =>
                                DropdownMenuItem(value: sex, child: Text(sex)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedSex = value),
                        decoration: _inputDecoration("Sex"),
                        validator: (value) => value == null ? "Select sex" : null,
                      ),
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveStudent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Save Student",
                            style: GoogleFonts.dmSans(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
