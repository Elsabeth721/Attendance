import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attendance_management_system/core/constants.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class ClassAttendancePage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassAttendancePage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassAttendancePage> createState() => _ClassAttendancePageState();
}

class _ClassAttendancePageState extends State<ClassAttendancePage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> allRecords = [];
  bool isLoading = true;
  bool isExporting = false;

  DateTime? startDate;
  DateTime? endDate;
  String selectedStatus = "All";
  String searchQuery = "";

  List<DateTime> uniqueDates = [];

  @override
  void initState() {
    super.initState();
    fetchAttendanceRecords();
  }

  Future<void> fetchAttendanceRecords() async {
    try {
      // Get students with phone numbers for this specific class
      final studentsResponse = await supabase
          .from("students")
          .select("id, first_name, last_name, phone_number1")
          .eq("grade_id", widget.classId);

      final studentIds =
          (studentsResponse as List).map((s) => s["id"] as String).toList();

      if (studentIds.isEmpty) {
        setState(() {
          allRecords = [];
          isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from("attendance")
          .select("attendance_date, status, student_id, id")
          .inFilter("student_id", studentIds)
          .order("attendance_date", ascending: true);

      // Create student map with phone numbers
      final studentMap = {
        for (var s in studentsResponse)
          s["id"]: {
            "name": "${s["first_name"]} ${s["last_name"]}",
            "phone": s["phone_number1"] ?? "N/A"
          }
      };

      setState(() {
        allRecords = (response as List).map<Map<String, dynamic>>((row) {
          final studentInfo = studentMap[row["student_id"]] ??
              {"name": "Unknown", "phone": "N/A"};
          return {
            "attendance_id": row["id"],
            "student_id": row["student_id"],
            "name": studentInfo["name"],
            "phone": studentInfo["phone"],
            "date": DateTime.parse(row["attendance_date"]),
            "status": row["status"] ?? "-",
          };
        }).toList();

        uniqueDates = allRecords
            .map((e) => e["date"] as DateTime)
            .toSet()
            .toList()
          ..sort((a, b) => a.compareTo(b));

        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("❌ Error fetching attendance: $e");
    }
  }

  Future<bool> _requestStoragePermission() async {
    try {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } catch (e) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> _exportToCSV() async {
    setState(() => isExporting = true);
    debugPrint("🔄 Starting CSV export...");

    try {
      debugPrint("📁 Requesting storage permission...");
      final hasPermission = await _requestStoragePermission();

      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Storage permission is required to save files. Please grant permission in app settings.',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        setState(() => isExporting = false);
        return;
      }

      final csvContent = _generateCSVContent();
      debugPrint("📊 CSV content generated: ${csvContent.length} characters");

      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      debugPrint("📂 Directory: ${directory.path}");

      final fileName =
          '${widget.className}_attendance_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final filePath = '${directory.path}/$fileName';
      debugPrint("💾 Saving to: $filePath");

      final file = File(filePath);
      await file.writeAsString(csvContent);
      debugPrint("✅ File saved successfully!");

      setState(() => isExporting = false);

      final result = await OpenFile.open(filePath);
      debugPrint("📤 Open file result: ${result.type} - ${result.message}");

      _showExportSuccess('CSV', filePath);
    } catch (e) {
      debugPrint("❌ Export error: $e");
      setState(() => isExporting = false);
      _showExportError(e.toString());
    }
  }

  Future<void> _exportToText() async {
    setState(() => isExporting = true);

    try {
      if (!await _requestStoragePermission()) {
        throw Exception('Storage permission is required to save files');
      }

      final textContent = _generateTextContent();

      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName =
          '${widget.className}_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(textContent);

      setState(() => isExporting = false);

      await OpenFile.open(filePath);

      _showExportSuccess('Text', filePath);
    } catch (e) {
      setState(() => isExporting = false);
      _showExportError(e.toString());
    }
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export ${widget.className} Attendance',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildExportOption(
                    icon: Icons.table_chart,
                    title: 'CSV File',
                    subtitle: 'Excel compatible',
                    color: AppColors.success,
                    onTap: _exportToCSV,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildExportOption(
                    icon: Icons.description,
                    title: 'Text Report',
                    subtitle: 'Detailed summary',
                    color: AppColors.primary,
                    onTap: _exportToText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Files will be saved to your Downloads folder',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _generateCSVContent() {
    final students = <String, Map<DateTime, String>>{};
    for (var record in filteredRecords) {
      students.putIfAbsent(record["name"], () => {});
      students[record["name"]]![record["date"]] = record["status"];
    }

    final csv = StringBuffer();

    // Header row
    csv.write('Student Name,');
    csv.write(filteredUniqueDates
        .map((d) => '"${DateFormat('MMM dd').format(d)}"')
        .join(','));
    csv.write(',Total Present,Total Absent,Total Patient\n');

    // Data rows
    students.forEach((name, dateStatuses) {
      int totalPresent = 0;
      int totalAbsent = 0;
      int totalPatient = 0;

      csv.write('"$name",');

      // Date columns
      for (var date in filteredUniqueDates) {
        final status = dateStatuses[date] ?? '-';
        if (status == "Present") totalPresent++;
        if (status == "Absent") totalAbsent++;
        if (status == "Patient") totalPatient++;

        csv.write('"$status",');
      }

      // Total columns
      csv.write('$totalPresent,$totalAbsent,$totalPatient\n');
    });

    return csv.toString();
  }

  String _generateTextContent() {
    final students = <String, Map<DateTime, String>>{};
    for (var record in filteredRecords) {
      students.putIfAbsent(record["name"], () => {});
      students[record["name"]]![record["date"]] = record["status"];
    }

    final text = StringBuffer();

    text.writeln('${widget.className.toUpperCase()} ATTENDANCE RECORDS REPORT');
    text.writeln('${'=' * (widget.className.length + 25)}');
    text.writeln(
        'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    text.writeln('Class: ${widget.className}');
    text.writeln('Period: ${_getPageTitle()}');
    text.writeln('Total Records: ${filteredRecords.length}');
    text.writeln('Total Students: ${students.length}');
    text.writeln();

    // Summary section
    text.writeln('SUMMARY STATISTICS:');
    text.writeln('-------------------');

    int totalPresent = 0;
    int totalAbsent = 0;
    int totalPatient = 0;

    students.forEach((name, dateStatuses) {
      for (var status in dateStatuses.values) {
        if (status == "Present") totalPresent++;
        if (status == "Absent") totalAbsent++;
        if (status == "Patient") totalPatient++;
      }
    });

    text.writeln('Total Present: $totalPresent');
    text.writeln('Total Absent: $totalAbsent');
    text.writeln('Total Patient: $totalPatient');
    text.writeln(
        'Attendance Rate: ${((totalPresent / filteredRecords.length) * 100).toStringAsFixed(1)}%');
    text.writeln();

    // Detailed section
    text.writeln('DETAILED STUDENT RECORDS:');
    text.writeln('-------------------------');

    students.forEach((name, dateStatuses) {
      text.writeln('STUDENT: $name');
      text.writeln('${'=' * (name.length + 9)}');

      int studentPresent = 0;
      int studentAbsent = 0;
      int studentPatient = 0;

      final sortedDates = dateStatuses.keys.toList()..sort();
      for (var date in sortedDates) {
        final status = dateStatuses[date]!;
        if (status == "Present") studentPresent++;
        if (status == "Absent") studentAbsent++;
        if (status == "Patient") studentPatient++;

        text.writeln(
            '  📅 ${DateFormat('MMM dd, yyyy').format(date)}: $status');
      }

      text.writeln();
      text.writeln('  📊 SUMMARY:');
      text.writeln('     Present: $studentPresent');
      text.writeln('     Absent: $studentAbsent');
      text.writeln('     Patient: $studentPatient');
      text.writeln(
          '     Attendance Rate: ${studentPresent + studentAbsent + studentPatient > 0 ? ((studentPresent / (studentPresent + studentAbsent + studentPatient)) * 100).toStringAsFixed(1) : 0}%');
      text.writeln();
    });

    return text.toString();
  }

  void _showExportSuccess(String format, String filePath) {
    final fileName = filePath.split('/').last;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  '$format file exported!',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Saved to Downloads folder',
              style: GoogleFonts.dmSans(
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Open',
          textColor: Colors.white,
          onPressed: () {
            OpenFile.open(filePath);
          },
        ),
      ),
    );
  }

  void _showExportError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  'Export failed',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: GoogleFonts.dmSans(
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateAttendanceStatus(String attendanceId, String newStatus,
      String studentId, DateTime date) async {
    try {
      debugPrint(
          "🔄 Updating attendance: attendanceId=$attendanceId, studentId=$studentId, date=$date, newStatus=$newStatus");

      // First check if we have a valid attendance ID
      if (attendanceId.isNotEmpty && attendanceId != "null") {
        // Update existing record - only update status
        await supabase.from("attendance").update({
          "status": newStatus,
        }).eq("id", attendanceId);

        debugPrint("✅ Updated existing record: $attendanceId");
      } else {
        // Create new record - make sure we have the correct date format
        final formattedDate = date.toIso8601String().split('T')[0];

        await supabase.from("attendance").insert({
          "student_id": studentId,
          "attendance_date": formattedDate,
          "status": newStatus,
        });

        debugPrint(
            "✅ Created new record for student: $studentId, date: $formattedDate");
      }

      // Refresh the data
      await fetchAttendanceRecords();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance updated successfully',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint("❌ Error updating attendance: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update attendance: $e',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteAttendanceRecord(String attendanceId) async {
    try {
      await supabase.from("attendance").delete().eq("id", attendanceId);

      fetchAttendanceRecords();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attendance record deleted successfully',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete attendance: $e',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredRecords {
    return allRecords.where((record) {
      final matchesStatus =
          selectedStatus == "All" || record["status"] == selectedStatus;
      final matchesDate = (startDate == null ||
              record["date"]
                  .isAfter(startDate!.subtract(const Duration(days: 1)))) &&
          (endDate == null ||
              record["date"].isBefore(endDate!.add(const Duration(days: 1))));
      final matchesSearch =
          record["name"].toLowerCase().contains(searchQuery.toLowerCase());

      return matchesStatus && matchesDate && matchesSearch;
    }).toList();
  }

  List<DateTime> get filteredUniqueDates {
    return uniqueDates.where((date) {
      final matchesDate = (startDate == null ||
              date.isAfter(startDate!.subtract(const Duration(days: 1)))) &&
          (endDate == null ||
              date.isBefore(endDate!.add(const Duration(days: 1))));
      return matchesDate;
    }).toList();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  void _showEditDialog(Map<String, dynamic> record) {
    String currentStatus = record["status"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Edit Attendance Status',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student: ${record["name"]}',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat("MMM dd, yyyy").format(record["date"])}',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current Status: ${record["status"]}',
                        style: GoogleFonts.dmSans(
                          color: _getStatusColor(record["status"]),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status Selection
                Text(
                  'Select New Status:',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ["Present", "Absent", "Patient"].map((status) {
                    final isSelected = currentStatus == status;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _getStatusIcon(status),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          currentStatus = status;
                        });
                      },
                      backgroundColor: AppColors.background,
                      selectedColor: _getStatusColor(status),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
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
                  _updateAttendanceStatus(
                      record["attendance_id"]?.toString() ?? "",
                      currentStatus,
                      record["student_id"]?.toString() ?? "",
                      record["date"]);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'Update Status',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Delete Record',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the attendance record for "${record["name"]}" on ${DateFormat("MMM dd, yyyy").format(record["date"])}? This action cannot be undone.',
          style: GoogleFonts.dmSans(),
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
              _deleteAttendanceRecord(record["attendance_id"]);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case "Present":
        return Icon(Icons.check_circle, color: AppColors.success, size: 18);
      case "Absent":
        return Icon(Icons.cancel, color: AppColors.error, size: 18);
      case "Patient":
        return Icon(Icons.medical_services, color: AppColors.warning, size: 18);
      default:
        return Icon(Icons.help, color: AppColors.textSecondary, size: 18);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Present":
        return AppColors.success;
      case "Absent":
        return AppColors.error;
      case "Patient":
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getPageTitle() {
    if (startDate == null && endDate == null) {
      return "${widget.className} - All Attendance";
    } else if (startDate != null && endDate != null) {
      final startFormat = DateFormat("MMM dd, yyyy").format(startDate!);
      final endFormat = DateFormat("MMM dd, yyyy").format(endDate!);
      return "${widget.className} ($startFormat - $endFormat)";
    } else if (startDate != null) {
      final startFormat = DateFormat("MMM dd, yyyy").format(startDate!);
      return "${widget.className} (From $startFormat)";
    } else {
      final endFormat = DateFormat("MMM dd, yyyy").format(endDate!);
      return "${widget.className} (Until $endFormat)";
    }
  }

  void _showStudentRecords(
      String studentName, Map<DateTime, Map<String, dynamic>> records) {
    final sortedDates = records.keys.toList()..sort();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Records',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                studentName,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final record = records[date]!;
                    final status = record["status"];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.border.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat("MMM dd, yyyy").format(date),
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _getStatusIcon(status),
                                    const SizedBox(width: 6),
                                    Text(
                                      status,
                                      style: GoogleFonts.dmSans(
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Find the original record to get student_id
                                  final originalRecord = allRecords.firstWhere(
                                    (r) =>
                                        r["name"] == studentName &&
                                        r["date"] == date,
                                    orElse: () => {},
                                  );

                                  _showEditDialog({
                                    "name": studentName,
                                    "date": date,
                                    "status": status,
                                    "attendance_id": record["attendance_id"],
                                    "student_id":
                                        originalRecord["student_id"] ?? "",
                                  });
                                },
                                icon:
                                    Icon(Icons.edit, color: AppColors.primary),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showDeleteConfirmation({
                                    "name": studentName,
                                    "date": date,
                                    "status": status,
                                    "attendance_id": record["attendance_id"],
                                  });
                                },
                                icon:
                                    Icon(Icons.delete, color: AppColors.error),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadStudentExcel(
      String studentName, Map<DateTime, Map<String, dynamic>> records) {
    final csvData = _generateStudentCSV(studentName, records);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'CSV data ready for $studentName (${records.length} records)',
                style: GoogleFonts.dmSans(),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success.withOpacity(0.9),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _generateStudentCSV(
      String studentName, Map<DateTime, Map<String, dynamic>> records) {
    final csv = StringBuffer();
    final sortedDates = records.keys.toList()..sort();

    csv.write('Student Name,Date,Status\n');

    for (var date in sortedDates) {
      final record = records[date]!;
      csv.write(
          '"$studentName",${DateFormat('yyyy-MM-dd').format(date)},${record["status"]}\n');
    }

    return csv.toString();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat("MMM dd");

    // Group by student with proper record data
    final students = <String, Map<DateTime, Map<String, dynamic>>>{};
    for (var record in filteredRecords) {
      students.putIfAbsent(record["name"], () => {});
      students[record["name"]]![record["date"]] = {
        "status": record["status"],
        "attendance_id": record["attendance_id"],
      };
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getPageTitle(),
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.appBar,
        elevation: 0,
        actions: [
          if (isExporting)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            )
          else
            IconButton(
              onPressed: _showExportMenu,
              icon: const Icon(Icons.download),
              tooltip: 'Export Data',
              color: AppColors.textOnPrimary,
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Attendance Records...',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filters Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Date Range
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickStartDate,
                              icon: Icon(Icons.calendar_today,
                                  color: AppColors.primary, size: 18),
                              label: Text(
                                startDate == null
                                    ? "Start Date"
                                    : DateFormat("MMM dd, yyyy")
                                        .format(startDate!),
                                style: GoogleFonts.dmSans(),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: BorderSide(color: AppColors.border),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickEndDate,
                              icon: Icon(Icons.calendar_today,
                                  color: AppColors.primary, size: 18),
                              label: Text(
                                endDate == null
                                    ? "End Date"
                                    : DateFormat("MMM dd, yyyy")
                                        .format(endDate!),
                                style: GoogleFonts.dmSans(),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: BorderSide(color: AppColors.border),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: selectedStatus,
                              items: ["All", "Present", "Absent", "Patient"]
                                  .map((status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(
                                          status,
                                          style: GoogleFonts.dmSans(
                                              color: AppColors.textSecondary),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() => selectedStatus = value!);
                              },
                              decoration: InputDecoration(
                                labelText: "Status",
                                labelStyle: GoogleFonts.dmSans(),
                                border: const OutlineInputBorder(),
                              ),
                              style: GoogleFonts.dmSans(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Search Student",
                                labelStyle: GoogleFonts.dmSans(),
                                prefixIcon: Icon(Icons.search,
                                    color: AppColors.primary),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                setState(() => searchQuery = value);
                              },
                              style: GoogleFonts.dmSans(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateColor.resolveWith(
                          (states) => AppColors.primary.withOpacity(0.1),
                        ),
                        dataRowColor: MaterialStateColor.resolveWith(
                          (states) => AppColors.surface,
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              "Student Name",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Phone Number",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          ...filteredUniqueDates.map((d) => DataColumn(
                                label: Text(
                                  dateFormatter.format(d),
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              )),
                          DataColumn(
                            label: Text(
                              "Present",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Absent",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Patient",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Actions",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                        rows: students.entries.map((entry) {
                          final name = entry.key;
                          final dateRecords = entry.value;
                          final studentRecord = allRecords.firstWhere(
                              (record) => record["name"] == name,
                              orElse: () => {"phone": "N/A"});
                          final phone = studentRecord["phone"] ?? "N/A";

                          int totalPresent = 0;
                          int totalAbsent = 0;
                          int totalPatient = 0;

                          final cells = <DataCell>[
                            DataCell(Text(
                              name,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                            DataCell(Text(
                              phone,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w500,
                              ),
                            )),
                            ...filteredUniqueDates.map((d) {
                              final record = dateRecords[d];
                              final status = record?["status"] ?? "-";
                              if (status == "Present") totalPresent++;
                              if (status == "Absent") totalAbsent++;
                              if (status == "Patient") totalPatient++;

                              final hasRecord = record != null;
                              Color statusColor = AppColors.textSecondary;
                              if (status == "Present")
                                statusColor = AppColors.success;
                              if (status == "Absent")
                                statusColor = AppColors.error;
                              if (status == "Patient")
                                statusColor = AppColors.warning;

                              // Find the original record to get student_id
                              final originalRecord = allRecords.firstWhere(
                                (r) => r["name"] == name && r["date"] == d,
                                orElse: () => {},
                              );

                              return DataCell(
                                InkWell(
                                  onTap: hasRecord
                                      ? () {
                                          _showEditDialog({
                                            "name": name,
                                            "phone": phone,
                                            "date": d,
                                            "status": status,
                                            "attendance_id":
                                                record!["attendance_id"],
                                            "student_id":
                                                originalRecord["student_id"] ??
                                                    "",
                                          });
                                        }
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: hasRecord
                                          ? statusColor.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                      border: hasRecord
                                          ? Border.all(
                                              color:
                                                  statusColor.withOpacity(0.3))
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _getStatusIcon(status),
                                        const SizedBox(width: 6),
                                        Text(
                                          status,
                                          style: GoogleFonts.dmSans(
                                            color: statusColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (hasRecord) ...[
                                          const SizedBox(width: 4),
                                          Icon(Icons.edit,
                                              color: statusColor, size: 12),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            DataCell(Text(
                              "$totalPresent",
                              style: GoogleFonts.dmSans(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                            DataCell(Text(
                              "$totalAbsent",
                              style: GoogleFonts.dmSans(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                            DataCell(Text(
                              "$totalPatient",
                              style: GoogleFonts.dmSans(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                            DataCell(
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert,
                                    color: AppColors.primary),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility,
                                            color: AppColors.info),
                                        const SizedBox(width: 8),
                                        Text('View All Records',
                                            style: GoogleFonts.dmSans()),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'export',
                                    child: Row(
                                      children: [
                                        Icon(Icons.download,
                                            color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text('Export Student',
                                            style: GoogleFonts.dmSans()),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'view') {
                                    _showStudentRecords(name, dateRecords);
                                  } else if (value == 'export') {
                                    _downloadStudentExcel(name, dateRecords);
                                  }
                                },
                              ),
                            ),
                          ];

                          return DataRow(cells: cells);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}