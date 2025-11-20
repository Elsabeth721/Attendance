import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:attendance_management_system/core/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

class IdCardDesignPage extends StatefulWidget {
  final String studentId;
  const IdCardDesignPage({super.key, required this.studentId});

  @override
  State<IdCardDesignPage> createState() => _IdCardDesignPageState();
}

class _IdCardDesignPageState extends State<IdCardDesignPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;
  Uint8List? _qrCodeImage;

  // Design options
  Color _cardColor = AppColors.primary;
  Color _textColor = Colors.white;
  String _selectedTemplate = 'modern';
  bool _showSchoolLogo = true;
  bool _showEmergencyInfo = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final response = await supabase
          .from('students')
          .select('''
            *,
            classes(name)
          ''')
          .eq('id', widget.studentId)
          .single();

      setState(() {
        _studentData = response;
        _isLoading = false;
      });

      // Generate QR code
      if (_studentData != null) {
        _generateQRCode();
      }
    } catch (e) {
      debugPrint('❌ Error loading student data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateQRCode() async {
    try {
      final qrData = _studentData?['qr_code_data'] ?? 'Student ID: ${_studentData?['student_id_number']}';
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      final imageData = await qrPainter.toImageData(200, format: ui.ImageByteFormat.png);
      if (imageData != null) {
        setState(() {
          _qrCodeImage = imageData.buffer.asUint8List();
        });
      }
    } catch (e) {
      debugPrint('❌ Error generating QR code: $e');
    }
  }

  Widget _buildIdCardPreview() {
    if (_studentData == null) return Container();

    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildIdCardContent(),
    );
  }

  Widget _buildIdCardContent() {
    final student = _studentData!;
    final className = student['classes']?['name'] ?? 'Unknown Class';
    
    return Stack(
      children: [
        // Background pattern
        if (_selectedTemplate == 'modern')
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _cardColor.withOpacity(0.8),
                  _cardColor.withOpacity(0.6),
                ],
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // School Header
              if (_showSchoolLogo) ...[
                Text(
                  'ፍሬ ሃይማኖት ት/ቤት',
                  style: GoogleFonts.dmSans(
                    color: _textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'FRUIT OF RELIGION SCHOOL',
                  style: GoogleFonts.dmSans(
                    color: _textColor.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(color: Colors.white54, height: 30),
              ],

              // Student Photo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: _textColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  image: student['photo_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(student['photo_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: student['photo_url'] == null
                    ? Icon(Icons.person, size: 50, color: _textColor)
                    : null,
              ),
              const SizedBox(height: 20),

              // Student Information
              Text(
                '${student['first_name']} ${student['last_name']}'.toUpperCase(),
                style: GoogleFonts.dmSans(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              _buildInfoRow('Student ID', student['student_id_number'] ?? 'N/A'),
              _buildInfoRow('Grade', className),
              _buildInfoRow('Group', student['group_name'] ?? 'N/A'),
              
              if (_showEmergencyInfo) ...[
                _buildInfoRow('Emergency', student['phone_number1'] ?? 'N/A'),
              ],

              const Spacer(),

              // QR Code
              if (_qrCodeImage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.memory(
                    _qrCodeImage!,
                    width: 100,
                    height: 100,
                  ),
                ),
              const SizedBox(height: 10),

              // Footer
              Text(
                'Valid until: ${_getExpiryDate()}',
                style: GoogleFonts.dmSans(
                  color: _textColor.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.dmSans(
              color: _textColor.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                color: _textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExpiryDate() {
    final issued = _studentData?['id_card_issued_date'];
    if (issued == null) return 'N/A';
    
    final issuedDate = DateTime.parse(issued);
    final expiryDate = DateTime(issuedDate.year + 1, issuedDate.month, issuedDate.day);
    return '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
  }

  Widget _buildDesignOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Design Options',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Template Selection
          _buildOptionSection(
            'Template',
            DropdownButton<String>(
              value: _selectedTemplate,
              items: ['modern', 'classic', 'minimal']
                  .map((template) => DropdownMenuItem(
                        value: template,
                        child: Text(template.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedTemplate = value!),
            ),
          ),

          // Color Selection
          _buildOptionSection(
            'Card Color',
            Row(
              children: [
                _buildColorOption(AppColors.primary),
                _buildColorOption(Colors.blue),
                _buildColorOption(Colors.green),
                _buildColorOption(Colors.purple),
                _buildColorOption(Colors.orange),
              ],
            ),
          ),

          // Text Color
          _buildOptionSection(
            'Text Color',
            Row(
              children: [
                _buildTextColorOption(Colors.white),
                _buildTextColorOption(Colors.black),
                _buildTextColorOption(Colors.blueGrey),
              ],
            ),
          ),

          // Toggle Options
          _buildOptionSection(
            'Display Options',
            Column(
              children: [
                SwitchListTile(
                  title: Text('Show School Logo', style: GoogleFonts.dmSans()),
                  value: _showSchoolLogo,
                  onChanged: (value) => setState(() => _showSchoolLogo = value),
                ),
                SwitchListTile(
                  title: Text('Show Emergency Info', style: GoogleFonts.dmSans()),
                  value: _showEmergencyInfo,
                  onChanged: (value) => setState(() => _showEmergencyInfo = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildColorOption(Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _cardColor = color),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: _cardColor == color
                ? Border.all(color: Colors.white, width: 2)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildTextColorOption(Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _textColor = color),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: _textColor == color
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: 350,
                height: 500,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(_cardColor.value),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Add PDF content similar to _buildIdCardContent()
                      // This would need to be implemented with pdf widgets
                      pw.Text(
                        'ID Card PDF',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('❌ Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  Future<void> _saveAsImage() async {
    // Implementation for saving as image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image save functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Design ID Card',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            onPressed: _generatePdf,
            tooltip: 'Print ID Card',
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _saveAsImage,
            tooltip: 'Save as Image',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview Section
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          'Preview',
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildIdCardPreview(),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _generatePdf,
                              icon: const Icon(Icons.print),
                              label: const Text('Print PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            OutlinedButton.icon(
                              onPressed: _saveAsImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Save as Image'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // Design Options Section
                  Expanded(
                    flex: 1,
                    child: _buildDesignOptions(),
                  ),
                ],
              ),
            ),
    );
  }
}