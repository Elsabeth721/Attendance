import 'package:attendance_management_system/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CreateAttendancePage extends StatefulWidget {
  final String adminEmail;
  const CreateAttendancePage({super.key, required this.adminEmail});

  @override
  State<CreateAttendancePage> createState() => _CreateAttendancePageState();
}

class _CreateAttendancePageState extends State<CreateAttendancePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> students = [];
  Map<String, String> studentAttendance = {}; // studentId -> status

  int presentCount = 0;
  int absentCount = 0;
  int patientCount = 0;

  String? classId;

  @override
  void initState() {
    super.initState();
    _fetchAdminClassAndStudents();
  }
Future<String?> _getAdminId() async {
  final response = await supabase
      .from('users')
      .select('id')
      .eq('email', widget.adminEmail)
      .maybeSingle();

  return response?['id'];
}

  Future<void> _fetchAdminClassAndStudents() async {
    try {
      // 1. Get admin class_id
      final admin = await supabase
          .from('users')
          .select('class_id')
          .eq('email', widget.adminEmail)
          .maybeSingle();

      if (admin == null || admin['class_id'] == null) {
        throw Exception("Admin's class not found");
      }

      classId = admin['class_id'];

      // 2. Fetch students for this class
      final studentResponse = await supabase
          .from('students')
          .select()
          .eq('grade_id', classId as Object);

      setState(() {
        students = List<Map<String, dynamic>>.from(studentResponse);
        for (var student in students) {
          studentAttendance[student['id']] = "Present"; // default
        }
        _updateSummary();
      });
        } catch (e) {
      debugPrint("❌ Error fetching students: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _updateSummary() {
    presentCount = 0;
    absentCount = 0;
    patientCount = 0;
    studentAttendance.forEach((key, value) {
      if (value == "Present") presentCount++;
      if (value == "Absent") absentCount++;
      if (value == "Patient") patientCount++;
    });
  }

  Future<void> _submitAttendance() async {
  if (classId == null) return;
  
  final today = DateTime.now();
  final todayStr = today.toIso8601String().split("T").first;
  
  try {
    // Check if attendance already exists for today in this class
    final existingAttendance = await supabase
        .from('attendance')
        .select('''
          id, student_id, status, 
          students (first_name, last_name)
        ''')
        .eq('attendance_date', todayStr)
        .eq('class_id', classId as Object);

    final existingRecords = List<Map<String, dynamic>>.from(existingAttendance);
    
    if (existingRecords.isNotEmpty) {
      // Show confirmation dialog with existing data
      await _showOverrideConfirmationDialog(existingRecords);
    } else {
      // No existing attendance, proceed directly
      await _saveAttendance();
    }
    
  } catch (e) {
    debugPrint("❌ Error checking existing attendance: $e");
    ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text("Error: $e")));
  }
}

Future<void> _showOverrideConfirmationDialog(List<Map<String, dynamic>> existingRecords) async {
  final todayFormatted = DateFormat('MMM dd, yyyy').format(DateTime.now());
  
  // Calculate changes
  final changes = <Map<String, dynamic>>[];
  for (var existingRecord in existingRecords) {
    final studentId = existingRecord['student_id'];
    final existingStatus = existingRecord['status'];
    final newStatus = studentAttendance[studentId];
    final student = existingRecord['students'] as Map<String, dynamic>;
    final studentName = '${student['first_name']} ${student['last_name']}';
    
    if (existingStatus != newStatus) {
      changes.add({
        'studentName': studentName,
        'from': existingStatus,
        'to': newStatus,
      });
    }
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.secondaryDark),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                'Attendance',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryDark, 
                ),
              ),
              Text(
                'Exists',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance for $todayFormatted already exists for ${existingRecords.length} students in this class.',
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (changes.isNotEmpty) ...[
            Text(
              'Changes that will be made:',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: changes.length,
                itemBuilder: (context, index) {
                  final change = changes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            change['studentName'],
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _buildStatusChip(change['from'], false),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        _buildStatusChip(change['to'], true),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppColors.info, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No changes detected from existing attendance.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          Text(
            'Do you want to override the existing attendance?',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _saveAttendance(override: true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryDark,
          ),
          child: Text(
            'Override Attendance',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildStatusChip(String status, bool isNew) {
  final color = _getStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(isNew ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      status,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

Future<void> _saveAttendance({bool override = false}) async {
  final today = DateTime.now();
  final adminId = await _getAdminId();
  final todayStr = today.toIso8601String().split("T").first;
  
  try {
    if (override) {
      // Delete existing attendance and insert new ones
      // First, delete existing attendance for today in this class
      await supabase
          .from('attendance')
          .delete()
          .eq('attendance_date', todayStr)
          .eq('class_id', classId as Object);
    }

    // Insert new attendance records
    final List<Map<String, dynamic>> attendanceData = [];
    
    for (var student in students) {
      final status = studentAttendance[student['id']]!;
      attendanceData.add({
        'student_id': student['id'],
        'status': status,
        'attendance_date': todayStr,
        'created_by': adminId,
        'class_id': classId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Batch insert all records
    await supabase.from('attendance').insert(attendanceData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          override 
            ? "✅ Attendance overridden successfully!"
            : "✅ Attendance submitted successfully!",
        ),
        backgroundColor: AppColors.success,
      ),
    );
    
    Navigator.pop(context);
    
  } catch (e) {
    debugPrint("❌ Error saving attendance: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error saving attendance: $e"),
        backgroundColor: AppColors.error,
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        backgroundColor: AppColors.primary,
        title: const Text(
          "Today's Attendance",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: students.isEmpty
          ? const Center(child: CircularProgressIndicator())
   : Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    children: [

      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                "Student Name",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                "Status",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),

      // Table Body
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: ListView.separated(
            itemCount: students.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: AppColors.border.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final student = students[index];
              final currentStatus = studentAttendance[student['id']] ?? "Present";
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: index.isEven ? AppColors.background : AppColors.surface,
                child: Row(
                  children: [
                    // Student Name
                    Expanded(
                      flex: 3,
                      child: Text(
                        "${student['first_name']} ${student['last_name']}",
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    
                    // Status Dropdown
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(currentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(currentStatus).withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: currentStatus,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: _getStatusColor(currentStatus),
                            ),
                            items: ["Present", "Absent", "Patient"].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    _getStatusIcon(status),
                                    const SizedBox(width: 8),
                                    Text(
                                      status,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                studentAttendance[student['id']] = value!;
                                _updateSummary();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),

      const SizedBox(height: 20),

      // Summary Cards in a row
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              "Attendance Summary",
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard("Present", presentCount, AppColors.primaryLight),
                _buildSummaryCard("Absent", absentCount, AppColors.error),
                _buildSummaryCard("Excused", patientCount, AppColors.secondaryDark),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 20),

      // Submit Button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimary,
            foregroundColor: AppColors.textOnPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 20),
              const SizedBox(width: 8),
              Text(
                "Submit Attendance",
                style: GoogleFonts.dmSans(
                  color: AppColors.textOnPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
);
  }

  Widget _summaryBox(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(count.toString(), style: TextStyle(color: color, fontSize: 18)),
        ],
      ),
    );
  }
}

Widget _buildSummaryCard(String title, int count, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.dmSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

Widget _getStatusIcon(String status) {
  switch (status) {
    case "Present":
      return Icon(Icons.check_circle, color: AppColors.success, size: 16);
    case "Absent":
      return Icon(Icons.cancel, color: AppColors.error, size: 16);
    case "Excused":
      return Icon(Icons.medical_services, color: AppColors.warning, size: 16);
    default:
      return Icon(Icons.help, color: AppColors.textSecondary, size: 16);
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case "Present":
      return AppColors.primaryLight;
    case "Absent":
      return AppColors.error;
    case "Excused":
      return AppColors.secondaryDark;
    default:
      return AppColors.textSecondary;
  }
}
