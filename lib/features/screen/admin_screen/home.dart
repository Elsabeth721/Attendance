import 'package:attendance_management_system/core/constants.dart';
import 'package:attendance_management_system/features/screen/Sidebar.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminHomePage extends StatefulWidget {
  final String adminName;
  final String adminEmail;
  const AdminHomePage(
      {super.key, required this.adminName, required this.adminEmail});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final supabase = Supabase.instance.client;

  int studentCount = 0;
  
  // Separate variables for pie chart (total) and latest attendance
  int totalPresentCount = 0;
  int totalAbsentCount = 0;
  int totalPatientCount = 0;
  
  int latestPresentCount = 0;
  int latestAbsentCount = 0;
  int latestPatientCount = 0;
  
  String? latestDate;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => isLoading = true);

    try {
      // ✅ Step 1: Find admin's class_id
      final adminRes = await supabase
          .from('users')
          .select('class_id')
          .eq('email', widget.adminEmail)
          .eq('role', 'admin')
          .maybeSingle();

      if (adminRes == null || adminRes['class_id'] == null) {
        throw Exception("No class assigned to this admin (${widget.adminEmail}).");
      }

      final classId = adminRes['class_id'];

      // ✅ Step 2: Count students
      final studentRes = await supabase
          .from('students')
          .select('id')
          .eq('grade_id', classId);

      studentCount = studentRes.length;

      // ✅ Step 3: Get TOTAL attendance counts for pie chart
      final totalAttendanceCounts = await supabase
          .from('attendance')
          .select('status')
          .eq('class_id', classId);

      // Reset total counts
      totalPresentCount = 0;
      totalAbsentCount = 0;
      totalPatientCount = 0;

      // Calculate total counts for pie chart
      for (var record in totalAttendanceCounts) {
        switch (record['status']) {
          case 'Present':
            totalPresentCount++;
            break;
          case 'Absent':
            totalAbsentCount++;
            break;
          case 'Patient':
            totalPatientCount++;
            break;
        }
      }

      // ✅ Step 4: Get latest date and LATEST attendance counts
      final latestDateRes = await supabase
          .from('attendance')
          .select('attendance_date')
          .eq('class_id', classId)
          .order('attendance_date', ascending: false)
          .limit(1);

      // Reset latest counts
      latestPresentCount = 0;
      latestAbsentCount = 0;
      latestPatientCount = 0;

      if (latestDateRes.isNotEmpty) {
        latestDate = latestDateRes.first['attendance_date'];
        
        // Get attendance for the latest date only
        final latestAttendanceRes = await supabase
            .from('attendance')
            .select('status')
            .eq('class_id', classId)
            .eq('attendance_date', latestDate!);

        // Calculate latest date counts
        for (var record in latestAttendanceRes) {
          switch (record['status']) {
            case 'Present':
              latestPresentCount++;
              break;
            case 'Absent':
              latestAbsentCount++;
              break;
            case 'Patient':
              latestPatientCount++;
              break;
          }
        }
      } else {
        latestDate = null;
      }

      debugPrint("📊 TOTAL Stats → P:$totalPresentCount, A:$totalAbsentCount, Pt:$totalPatientCount");
      debugPrint("📅 LATEST Stats → P:$latestPresentCount, A:$latestAbsentCount, Pt:$latestPatientCount");
      debugPrint("📅 Latest date: $latestDate");

      setState(() => isLoading = false);
    } catch (e, stack) {
      debugPrint("❌ Error in _fetchDashboardData: $e");
      debugPrint("📍 Stacktrace: $stack");
      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Could not fetch data: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary), 
        title: Text(
          'Welcome, ${widget.adminName} ',
          style: GoogleFonts.dmSans(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchDashboardData,
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: SidebarMenu(
        userRole: 'admin',
        userName: widget.adminName,
        adminEmail: widget.adminEmail,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Dashboard...',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(),
                  const SizedBox(height: 24),
                  _buildAttendanceOverview(), // Pie chart - uses TOTAL counts
                  const SizedBox(height: 24),
                  _buildLatestAttendance(), // Latest section - uses LATEST counts
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.primaryLight.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            studentCount.toString(),
            style: GoogleFonts.dmSans(
              color: AppColors.textOnPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Students',
            style: GoogleFonts.dmSans(
              color: AppColors.textOnPrimary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppColors.border.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Attendance Overview",
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "All-time statistics",
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          
          if (totalPresentCount == 0 && totalAbsentCount == 0 && totalPatientCount == 0)
            _buildEmptyState()
          else
            Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: totalPresentCount.toDouble(),
                          color: AppColors.primaryLight,
                          title: "Present",
                          radius: 60,
                          titleStyle: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalAbsentCount.toDouble(),
                          color: AppColors.error,
                          title: "Absent",
                          radius: 60,
                          titleStyle: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        PieChartSectionData(
                          value: totalPatientCount.toDouble(),
                          color: AppColors.secondaryDark,
                          title: "Excused",
                          radius: 60,
                          titleStyle: GoogleFonts.dmSans(
                            color: AppColors.textOnSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      centerSpaceColor: AppColors.background,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildChartLegend(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 60,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No attendance data available",
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Attendance records will appear here",
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(AppColors.primaryLight, "Present", totalPresentCount),
        _buildLegendItem(AppColors.error, "Absent", totalAbsentCount),
        _buildLegendItem(AppColors.secondaryDark, "Excused", totalPatientCount),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, int count) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLatestAttendance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppColors.border.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                "Latest Attendance Summary",
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            latestDate ?? "No date available",
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          
          if (latestDate == null)
            _buildEmptyAttendanceState()
          else
            Column(
              children: [
                _buildAttendanceStatusRow(
                  "Present Students",
                  latestPresentCount, // Use latest counts
                  AppColors.primaryLight,
                  Icons.check_circle,
                ),
                const SizedBox(height: 12),
                _buildAttendanceStatusRow(
                  "Absent Students",
                  latestAbsentCount, // Use latest counts
                  AppColors.error,
                  Icons.cancel,
                ),
                const SizedBox(height: 12),
                _buildAttendanceStatusRow(
                  "Excused Students",
                  latestPatientCount, // Use latest counts
                  AppColors.secondaryDark,
                  Icons.medical_services,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.primaryLight.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Students:",
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "$studentCount",
                        style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyAttendanceState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 50,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No attendance records",
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Attendance data will appear here once recorded",
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatusRow(String status, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}