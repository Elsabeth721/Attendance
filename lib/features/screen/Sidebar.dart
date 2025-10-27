import 'package:attendance_management_system/core/constants.dart';
import 'package:attendance_management_system/features/screen/admin_screen/add_student.dart';
import 'package:attendance_management_system/features/screen/admin_screen/create_todays_attendance.dart';
import 'package:attendance_management_system/features/screen/admin_screen/all_attendance.dart'; // Add this import
import 'package:attendance_management_system/features/screen/login.dart';
import 'package:attendance_management_system/features/screen/superadmin_screen/list_admin.dart';
import 'package:attendance_management_system/features/screen/superadmin_screen/list_class.dart';
import 'package:flutter/material.dart'; 
import 'package:google_fonts/google_fonts.dart';

class SidebarMenu extends StatelessWidget {
  final String userRole; // 'superadmin' or 'admin'
  final String userName;
  final String? adminEmail; // Make it optional for superadmin
  
  const SidebarMenu({
    super.key,
    required this.userRole,
    required this.userName,
    this.adminEmail, // Optional parameter
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      
      width: 260,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header
              Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/logo.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              userRole == 'superadmin' ? 'S-Admin' : 'Admin',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ),
              ),

              // Menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                child: Column(
                  children: _buildMenuItems(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    if (userRole == 'superadmin') {
      return [
        buildMenuItem(
          context,
          Icons.class_,
          "Class",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ListClassesPage()),
          ),
        ),
        buildMenuItem(
          context,
          Icons.admin_panel_settings,
          "Admin",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ListAdminsPage()),
          ),
        ),
        const Divider(),
        buildMenuItem(
          context,
          Icons.logout,
          "Sign Out",
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          ),
        ),
      ];
    } else {
      // Admin menu items - require adminEmail
      if (adminEmail == null) {
        return [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Error: Admin email not available'),
          ),
          buildMenuItem(
            context,
            Icons.logout,
            "Sign Out",
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            ),
          ),
        ];
      }

      return [
        buildMenuItem(
          context,
          Icons.people,
          "Add Students",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddStudentPage(adminEmail: adminEmail!)),
            );
          },
        ),
        buildMenuItem(
          context,
          Icons.calendar_today,
          "Create Attendance",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateAttendancePage(adminEmail: adminEmail!)),
            );
          },
        ),
        buildMenuItem(
          context,
          Icons.list_alt,
          "All Attendance",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AllAttendancePage(adminEmail: adminEmail!)),
            );
          },
        ),
        const Divider(),
        buildMenuItem(
          context,
          Icons.logout,
          "Sign Out",
          onTap: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          ),
        ),
      ];
    }
  }

  Widget buildMenuItem(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 15),
            Text(
              title,
              style: GoogleFonts.dmSans(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}