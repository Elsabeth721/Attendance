import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:attendance_management_system/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddStudentPage extends StatefulWidget {
  final String adminEmail;
  const AddStudentPage({super.key, required this.adminEmail});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  // Existing controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();

  // New controllers for enhanced fields
  final _motherNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  String? _selectedSex;
  String? _selectedHomeStatus;
  String? _selectedGroup;
  String? _adminClassId;
  File? _selectedPhoto;

  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  // Ethiopian date variables
  int? _selectedEthYear;
  int? _selectedEthMonth;
  int? _selectedEthDay;

  @override
  void initState() {
    super.initState();
    _loadAdminClass();
    _initializeEthiopianDate();
  }

  void _initializeEthiopianDate() {
    final now = DateTime.now();
    _selectedEthYear = now.year - 8;
    _selectedEthMonth = 1;
    _selectedEthDay = 1;
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _selectedPhoto = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadStudentPhoto(File imageFile, String studentId) async {
    final storagePath = 'student-photos/$studentId.jpg';
    await supabase.storage
      .from('student-photos')
      .upload(storagePath, imageFile);
    
    return supabase.storage
      .from('student-photos')
      .getPublicUrl(storagePath);
  }

 Future<String> _generateAndStoreQRCode(String studentId, Map<String, dynamic> studentData) async {
  try {
    // Wait a bit for the trigger to complete
    await Future.delayed(Duration(milliseconds: 500));
    
    // Get the student with the auto-generated ID
    final studentResponse = await supabase
      .from('students')
      .select('student_id_number, first_name, last_name, phone_number1')
      .eq('id', studentId)
      .single();
    
    final studentIdNumber = studentResponse['student_id_number'];
    final firstName = studentResponse['first_name'];
    final lastName = studentResponse['last_name'];
    
    if (studentIdNumber == null) {
      debugPrint('⚠️ Student ID number is still null, using fallback');
      final tempId = 'TEMP-${DateTime.now().millisecondsSinceEpoch}';
      await supabase
        .from('students')
        .update({'student_id_number': tempId})
        .eq('id', studentId);
    }

    final effectiveStudentId = studentIdNumber ?? 'TEMP-${DateTime.now().millisecondsSinceEpoch}';

    // Create QR code data
    final qrData = jsonEncode({
      'student_id': effectiveStudentId,
      'name': '$firstName $lastName',
      'phone': studentResponse['phone_number1'],
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Generate QR code image
    final qrImageBytes = await _generateQRCodeImage(qrData);

    // **UPDATED: Create filename with student name**
    String sanitizedName = _sanitizeFileName('$firstName $lastName');
    final storagePath = 'qr-codes/${sanitizedName}_$effectiveStudentId.png';
    
    debugPrint('💾 Saving QR code as: $storagePath');

    // Upload using the Uint8List directly
    final imageBytes = qrImageBytes;
    
    await supabase.storage
      .from('qr-codes')
      .uploadBinary(storagePath, imageBytes);

    // Get public URL
    final qrImageUrl = supabase.storage
      .from('qr-codes')
      .getPublicUrl(storagePath);

    debugPrint('🔄 Updating student with QR data...');
    
    // Update student record with both QR data and image URL
    final updateResponse = await supabase
      .from('students')
      .update({
        'qr_code_data': qrData,
        'qr_code_image_url': qrImageUrl,
      })
      .eq('id', studentId)
      .select();

    debugPrint('✅ QR code update response: ${updateResponse.length}');

    debugPrint('✅ QR code generated and stored: $qrImageUrl');
    debugPrint('📊 QR data: $qrData');
    
    return qrImageUrl;
  } catch (e) {
    debugPrint('❌ Error generating QR code: $e');
    debugPrint('📌 Error type: ${e.runtimeType}');
    
    // Even if QR fails, store the data
    try {
      final studentResponse = await supabase
        .from('students')
        .select('student_id_number, first_name, last_name')
        .eq('id', studentId)
        .single();
      
      final studentIdNumber = studentResponse['student_id_number'] ?? 'TEMP-ID';
      final firstName = studentResponse['first_name'];
      final lastName = studentResponse['last_name'];
      final qrData = jsonEncode({
        'student_id': studentIdNumber,
        'name': '$firstName $lastName',
      });
      
      await supabase
        .from('students')
        .update({'qr_code_data': qrData})
        .eq('id', studentId);
        
      debugPrint('✅ QR data stored (image generation failed)');
    } catch (e2) {
      debugPrint('❌ Failed to store QR data: $e2');
    }
    
    return '';
  }
}

// Helper method to sanitize file names
String _sanitizeFileName(String name) {
  // Remove or replace characters that are not allowed in file names
  return name
      .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_') // Replace invalid characters with underscore
      .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscore
      .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single
      .trim() // Remove leading/trailing whitespace
      .toLowerCase(); // Convert to lowercase for consistency
}
  // FIXED: Correct QR Image Generation
  Future<Uint8List> _generateQRCodeImage(String data) async {
    try {
      // Use QrPainter to generate QR code
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
        gapless: false,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      // Convert to image data
      final imageData = await qrPainter.toImageData(300, format: ui.ImageByteFormat.png);
      
      if (imageData == null) {
        throw Exception('Failed to generate QR code image');
      }

      return imageData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ QR image generation error: $e');
      // Return a simple placeholder
      return _createPlaceholderQRCode();
    }
  }

  Uint8List _createPlaceholderQRCode() {
    // Simple placeholder - create a 300x300 white image with text
    final placeholder = '''
      <svg width="300" height="300" xmlns="http://www.w3.org/2000/svg">
        <rect width="100%" height="100%" fill="white"/>
        <text x="150" y="150" font-family="Arial" font-size="20" text-anchor="middle" fill="black">QR CODE</text>
      </svg>
    ''';
    return Uint8List.fromList(placeholder.codeUnits);
  }

  // FIXED: Save Student Method
  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEthYear == null || _selectedEthMonth == null || _selectedEthDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select date of birth")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final adminRecord = await supabase
          .from('users')
          .select('id, class_id')
          .eq('email', widget.adminEmail)
          .maybeSingle();

      if (adminRecord == null || adminRecord['class_id'] == null) {
        throw Exception("Admin's class not found.");
      }

      final classId = adminRecord['class_id'];

      // Convert Ethiopian to Gregorian date
      final gregorianDob = _convertToGregorian(
        _selectedEthYear!, _selectedEthMonth!, _selectedEthDay!
      );

      // Prepare student data - let trigger handle student_id_number and id_card_issued_date
      final studentData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number1': _phone1Controller.text.trim(),
        'phone_number2': _phone2Controller.text.trim().isEmpty ? null : _phone2Controller.text.trim(),
        'sex': _selectedSex,
        'grade_id': classId,
        'created_by': adminRecord['id'], 
        
        // New fields
        'mother_name': _motherNameController.text.trim(),
        'father_name': _fatherNameController.text.trim(),
        'address': _addressController.text.trim(),
        'home_status': _selectedHomeStatus,
        'group_name': _selectedGroup,
        'date_of_birth_gregorian': gregorianDob.toIso8601String().split('T')[0],
        'date_of_birth_ethiopian': '$_selectedEthYear-${_selectedEthMonth.toString().padLeft(2, '0')}-${_selectedEthDay.toString().padLeft(2, '0')}',
      };

      // Insert student - trigger should auto-generate student_id_number
      final response = await supabase
          .from('students')
          .insert(studentData)
          .select();
      
      final newStudent = response.first;
      final studentId = newStudent['id'];
      final studentIdNumber = newStudent['student_id_number'];
      final issuedDate = newStudent['id_card_issued_date'];

      debugPrint('✅ Student created with ID: $studentId');
      debugPrint('🎫 Student ID Number: $studentIdNumber');
      debugPrint('📅 ID Card Issued: $issuedDate');

      // Upload photo if selected
      if (_selectedPhoto != null) {
        try {
          final photoUrl = await _uploadStudentPhoto(_selectedPhoto!, studentId);
          await supabase
            .from('students')
            .update({'photo_url': photoUrl})
            .eq('id', studentId);
          debugPrint('✅ Photo uploaded: $photoUrl');
        } catch (e) {
          debugPrint('⚠️ Photo upload failed: $e');
          // Continue even if photo upload fails
        }
      }

      // Generate and store QR code
      try {
        final qrImageUrl = await _generateAndStoreQRCode(studentId, newStudent);
        debugPrint('📱 QR Code generated: $qrImageUrl');
      } catch (e) {
        debugPrint('⚠️ QR code generation failed: $e');
        // Continue even if QR generation fails
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Student added successfully! ID: ${studentIdNumber ?? 'Pending'}")),
      );

      // Wait a bit before navigating to show the success message
      await Future.delayed(Duration(seconds: 1));
      Navigator.pop(context);

    } catch (e, stack) {
      debugPrint("❌ Error adding student: $e");
      debugPrint("📌 Stack trace: $stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error adding student: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  DateTime _convertToGregorian(int ethYear, int ethMonth, int ethDay) {
    var gregYear = ethYear + 8;
    int gregMonth = ethMonth + 8;
    int gregDay = ethDay;
    
    if (gregMonth > 12) {
      gregYear += 1;
      gregMonth -= 12;
    }
    
    return DateTime(gregYear, gregMonth, gregDay);
  }

  // ... Rest of your UI methods remain the same (_buildPhotoSection, _buildEthiopianDatePicker, etc.)
  // Keep all the UI methods as they are in your original code

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Student Photo",
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedPhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedPhoto!, fit: BoxFit.cover),
                    )
                  : Icon(Icons.person, size: 40, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: Icon(Icons.camera_alt),
                  label: Text("Take Photo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_library),
                  label: Text("Choose from Gallery"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEthiopianDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of Birth (Ethiopian Calendar)",
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedEthYear,
                items: List.generate(30, (index) => 1990 + index)
                    .map((year) => DropdownMenuItem(
                          value: year,
                          child: Text('$year ዓ.ም'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedEthYear = value),
                decoration: _inputDecoration("Year"),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedEthMonth,
                items: List.generate(13, (index) => index + 1)
                    .map((month) => DropdownMenuItem(
                          value: month,
                          child: Text(_getEthiopianMonthName(month)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedEthMonth = value),
                decoration: _inputDecoration("Month"),
              ),
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _selectedEthDay,
                items: List.generate(_getDaysInMonth(_selectedEthMonth ?? 1, _selectedEthYear ?? 2016), 
                        (index) => index + 1)
                    .map((day) => DropdownMenuItem(
                          value: day,
                          child: Text('$day'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedEthDay = value),
                decoration: _inputDecoration("Day"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getEthiopianMonthName(int month) {
    const months = [
      'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
      'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜ'
    ];
    return months[month - 1];
  }

  int _getDaysInMonth(int month, int year) {
    if (month == 13) {
      return _isEthiopianLeapYear(year) ? 6 : 5;
    }
    return 30;
  }

  bool _isEthiopianLeapYear(int year) {
    return (year + 8) % 4 == 0;
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
                      _buildPhotoSection(),
                      Text(
                        "Personal Information",
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _firstNameController,
                        decoration: _inputDecoration("First Name *"),
                        validator: (value) => value!.isEmpty ? "Enter first name" : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _lastNameController,
                        decoration: _inputDecoration("Last Name *"),
                        validator: (value) => value!.isEmpty ? "Enter last name" : null,
                      ),
                      const SizedBox(height: 15),
                      _buildEthiopianDatePicker(),
                      DropdownButtonFormField<String>(
                        value: _selectedSex,
                        items: ["Male", "Female"]
                            .map((sex) => DropdownMenuItem(value: sex, child: Text(sex)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedSex = value),
                        decoration: _inputDecoration("Sex *"),
                        validator: (value) => value == null ? "Select sex" : null,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Family Information",
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _motherNameController,
                        decoration: _inputDecoration("Mother's Name"),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _fatherNameController,
                        decoration: _inputDecoration("Father's Name"),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedHomeStatus,
                        items: ["parent", "alone", "sis_bro"]
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(_getHomeStatusDisplayName(status)),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedHomeStatus = value),
                        decoration: _inputDecoration("Home Status"),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Contact Information",
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _phone1Controller,
                        decoration: _inputDecoration("Phone Number 1 *"),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value!.isEmpty ? "Enter phone number" : null,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _phone2Controller,
                        decoration: _inputDecoration("Phone Number 2 (Optional)"),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _emergencyContactController,
                        decoration: _inputDecoration("Emergency Contact"),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        style: GoogleFonts.dmSans(),
                        controller: _addressController,
                        decoration: _inputDecoration("Address"),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "Academic Information",
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGroup,
                        items: ["Group1", "Group2", "Group3", "Group4"]
                            .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedGroup = value),
                        decoration: _inputDecoration("Group"),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveStudent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                    ),
                                    const SizedBox(width: 12),
                                    Text("Saving...", style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : Text("Save Student", style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _getHomeStatusDisplayName(String status) {
    switch (status) {
      case 'parent': return 'With Parents';
      case 'alone': return 'Alone';
      case 'sis_bro': return 'With Siblings';
      default: return status;
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}