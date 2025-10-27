import 'package:attendance_management_system/features/screen/Sidebar.dart';
import 'package:attendance_management_system/features/screen/superadmin_screen/home_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class SuperAdminHomePage extends StatefulWidget {
  const SuperAdminHomePage({Key? key}) : super(key: key);

  @override
  State<SuperAdminHomePage> createState() => _SuperAdminHomePageState();
}

class _SuperAdminHomePageState extends State<SuperAdminHomePage> {
  // ✅ Define the GlobalKey first
  final GlobalKey<HomeChartState> _homeChartKey = GlobalKey<HomeChartState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 204, 226, 241),
      appBar: AppBar(
        title: const Text("Super Admin Dashboard"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Dashboard",
            onPressed: () {
              // ✅ Call fetchDashboardData directly
              _homeChartKey.currentState?.fetchDashboardData();
            },
          ),
        ],
      ),
      drawer: const SidebarMenu(userRole: 'superadmin', userName: ''),
      body: HomeChart(key: _homeChartKey), // ✅ Pass the key here
    );
  }
}