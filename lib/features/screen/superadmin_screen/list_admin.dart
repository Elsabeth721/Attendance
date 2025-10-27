import 'package:attendance_management_system/core/constants.dart';
import 'package:attendance_management_system/features/screen/superadmin_screen/create_admin.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ListAdminsPage extends StatefulWidget {
  const ListAdminsPage({Key? key}) : super(key: key);

  @override
  State<ListAdminsPage> createState() => _ListAdminsPageState();
}

class _ListAdminsPageState extends State<ListAdminsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  /// Fetch admins with their class names
  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('users')
          .select('id, username, email, role, phone_number, class_id, classes(name)')
          .eq('role', 'admin'); // only admins

      setState(() {
        _admins = List<Map<String, dynamic>>.from(response);
      });
      debugPrint("✅ Fetched admins: $_admins");
    } catch (e, stack) {
      debugPrint("❌ Error fetching admins: $e");
      debugPrint("📌 Stack: $stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error fetching admins: $e",
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAdmin(String adminId, String adminName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Delete Admin',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete admin "$adminName"? This action cannot be undone.',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

    if (confirmed == true) {
      try {
        await supabase
            .from('users')
            .delete()
            .eq('id', adminId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Admin "$adminName" deleted successfully',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.success,
          ),
        );

        _fetchAdmins(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error deleting admin: $e',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAdminOptions(BuildContext context, Map<String, dynamic> admin) {
    final className = admin['classes'] != null ? admin['classes']['name'] : "No class";
    
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
              admin['username'] ?? "Unnamed Admin",
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              admin['email'] ?? '-',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Class: $className",
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Edit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditAdminDialog(admin);
                },
                icon: Icon(Icons.edit, size: 20),
                label: Text(
                  'Edit Admin',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Delete Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteAdmin(admin['id'], admin['username'] ?? 'Admin');
                },
                icon: Icon(Icons.delete, size: 20, color: AppColors.error),
                label: Text(
                  'Delete Admin',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Cancel Button
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

  Future<void> _showEditAdminDialog(Map<String, dynamic> admin) async {
    final nameController = TextEditingController(text: admin['username'] ?? '');
    final emailController = TextEditingController(text: admin['email'] ?? '');
    final phoneController = TextEditingController(text: admin['phone_number'] ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Admin',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: GoogleFonts.dmSans(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.dmSans(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.dmSans(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.dmSans(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: GoogleFonts.dmSans(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.dmSans(),
              ),
            ],
          ),
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
            onPressed: () async {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final newPhone = phoneController.text.trim();
              
              if (newName.isEmpty || newEmail.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please fill in all required fields',
                      style: GoogleFonts.dmSans(),
                    ),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              
              try {
                await supabase
                    .from('users')
                    .update({
                      'username': newName,
                      'email': newEmail,
                      'phone_number': newPhone,
                    })
                    .eq('id', admin['id']);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Admin updated successfully',
                      style: GoogleFonts.dmSans(),
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                
                Navigator.pop(context);
                _fetchAdmins(); // Refresh the list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '❌ Error updating admin: $e',
                      style: GoogleFonts.dmSans(),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              'Update',
              style: GoogleFonts.dmSans(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Admins List",
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    "Loading Admins...",
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _admins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No admins available",
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create your first admin to get started",
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _admins.length,
                  itemBuilder: (context, index) {
                    final admin = _admins[index];
                    final className =
                        admin['classes'] != null ? admin['classes']['name'] : "No class";

                    return Card(
                      color: AppColors.surface,
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person, color: AppColors.textOnPrimary),
                        ),
                        title: Text(
                          admin['username'] ?? "Unnamed Admin",
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Email: ${admin['email'] ?? '-'}",
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Phone: ${admin['phone_number'] ?? '-'}",
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "Class: $className",
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.more_vert, color: AppColors.primary),
                          onPressed: () => _showAdminOptions(context, admin),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAdminScreen()),
          ).then((_) => _fetchAdmins());
        },
        backgroundColor: AppColors.buttonPrimary,
        child: Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
    );
  }
}