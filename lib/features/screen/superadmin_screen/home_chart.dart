import 'package:attendance_management_system/core/constants.dart';
import 'package:attendance_management_system/features/screen/Sidebar.dart';
import 'package:attendance_management_system/features/screen/superadmin_screen/home.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeChart extends StatefulWidget {
  const HomeChart({Key? key}) : super(key: key);

  @override
  State<HomeChart> createState() => HomeChartState();
}

class HomeChartState extends State<HomeChart> {
  int totalClasses = 0;
  int totalAdmins = 0;
  int present = 0;
  int absent = 0;
  int patient = 0;

  Map<String, Map<String, int>> _classAttendance = {};

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  // ✅ Make this method public so it can be called from outside
  Future<void> fetchDashboardData() async {
    try {
      final supabase = Supabase.instance.client;

      // ✅ Fetch total classes
      final classesRes = await supabase.from('classes').select();
      totalClasses = classesRes.length;

      // ✅ Fetch total admins from users table
      final adminsRes = await supabase.from('users').select().eq('role', 'admin');
      totalAdmins = adminsRes.length;

      // ✅ Create class ID to name mapping with proper type conversion
      final classMap = {
        for (var c in classesRes) 
          c['id'].toString(): c['name'] ?? 'Unnamed Class'
      };

      // ✅ Find the latest attendance date overall
      final latestDateRes = await supabase
          .from('attendance')
          .select('attendance_date')
          .order('attendance_date', ascending: false)
          .limit(1);

      if (latestDateRes.isNotEmpty) {
        final latestDate = latestDateRes.first['attendance_date'];
        debugPrint("📊 Latest attendance date: $latestDate");

        // ✅ Get ALL attendance records for the latest date (not just one per class)
        final allLatestAttendance = await supabase
            .from('attendance')
            .select('status, class_id')
            .eq('attendance_date', latestDate);

        // Reset overall counts
        present = 0;
        absent = 0;
        patient = 0;

        // Group by class and count ALL records
        Map<String, Map<String, int>> classStats = {};

        for (var record in allLatestAttendance) {
          final classId = record['class_id'].toString();
          final className = classMap[classId] ?? 'Class $classId';
          final status = record['status'];

          // Initialize class stats if not exists
          classStats[className] ??= {"Present": 0, "Absent": 0, "Patient": 0};

          // Update counts for ALL records
          if (status == "Present") {
            present++;
            classStats[className]!["Present"] = (classStats[className]!["Present"] ?? 0) + 1;
          } else if (status == "Absent") {
            absent++;
            classStats[className]!["Absent"] = (classStats[className]!["Absent"] ?? 0) + 1;
          } else if (status == "Patient") {
            patient++;
            classStats[className]!["Patient"] = (classStats[className]!["Patient"] ?? 0) + 1;
          }
        }

        setState(() {
          _classAttendance = classStats;
        });

        debugPrint("📊 Latest date: $latestDate");
        debugPrint("📊 Overall → P:$present, A:$absent, Pt:$patient");
        debugPrint("📊 Class stats: $_classAttendance");
      } else {
        debugPrint("📊 No attendance records found");
        setState(() {
          _classAttendance = {};
          present = 0;
          absent = 0;
          patient = 0;
        });
      }

      setState(() {});
    } catch (e) {
      debugPrint("❌ Error fetching dashboard data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const SidebarMenu(userRole: 'superadmin', userName: ''),
      body: SafeArea(
        
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchDashboardData,
                  child: ListView(
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 20),
                      _buildScrollableContent(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 100,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard("Total Classes", "$totalClasses", Icons.class_),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard("Total Admins", "$totalAdmins", Icons.admin_panel_settings),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Overall Pie Chart Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Last Date Attendance Overview (Overall)",
                    style: GoogleFonts.dmSans( // Changed to dmSans
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: present == 0 && absent == 0 && patient == 0
                        ? _buildNoDataPlaceholder()
                        : PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: present.toDouble(),
                                  title: "Present\n$present",
                                  color: AppColors.primaryLight, // Updated color
                                  radius: 70,
                                  titleStyle: GoogleFonts.dmSans( // Changed to dmSans
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: absent.toDouble(),
                                  title: "Absent\n$absent",
                                  color: AppColors.error, // Updated color
                                  radius: 70,
                                  titleStyle: GoogleFonts.dmSans( // Changed to dmSans
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                PieChartSectionData(
                                  value: patient.toDouble(),
                                  title: "Patient\n$patient",
                                  color: AppColors.secondaryDark, // Updated color
                                  radius: 70,
                                  titleStyle: GoogleFonts.dmSans( // Changed to dmSans
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Class-wise Attendance Section
          if (_classAttendance.isNotEmpty) ...[
            Text(
              "Class-wise Attendance",
              style: GoogleFonts.dmSans( // Changed to dmSans
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._classAttendance.entries.map((entry) {
              final className = entry.key;
              final stats = entry.value;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: GoogleFonts.dmSans( // Changed to dmSans
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatus("Present", stats["Present"]!, AppColors.primaryLight),
                          _buildStatus("Absent", stats["Absent"]!, AppColors.error),
                          _buildStatus("Patient", stats["Patient"]!, AppColors.secondaryDark),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ] else ...[
            _buildNoClassesPlaceholder(),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count,
                    style: GoogleFonts.dmSans( // Changed to dmSans
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.dmSans( // Changed to dmSans
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          "$count",
          style: GoogleFonts.dmSans( // Changed to dmSans
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.dmSans( // Changed to dmSans
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No attendance data available",
            style: GoogleFonts.dmSans( // Changed to dmSans
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoClassesPlaceholder() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.class_,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              "No class attendance data",
              style: GoogleFonts.dmSans( // Changed to dmSans
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Attendance records will appear here once created",
              style: GoogleFonts.dmSans( // Changed to dmSans
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}