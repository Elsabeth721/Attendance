import 'package:attendance_management_system/core/constants.dart';
import 'package:attendance_management_system/features/screen/superadmin_screen/creat_class.dart';
import 'package:attendance_management_system/features/screen/superadmin_screen/class_attendance_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ListClassesPage extends StatefulWidget {
  const ListClassesPage({Key? key}) : super(key: key);

  @override
  State<ListClassesPage> createState() => _ListClassesPageState();
}

class _ListClassesPageState extends State<ListClassesPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Fetch classes with student count
      final response = await supabase
          .from('classes')
          .select('id, name, students(id)')
          .order('name');

      setState(() {
        _classes = response.map((c) {
          return {
            'id': c['id'],
            'name': c['name'],
            'student_count': (c['students'] as List).length,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error fetching classes: $e")),
      );
    }
  }

  Future<void> _deleteClass(String classId, String className) async {
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
              'Delete Class',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$className"? This action cannot be undone and will remove all associated students and attendance records.',
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
        // First delete related records (students, attendance)
        await supabase
            .from('students')
            .delete()
            .eq('grade_id', classId);

        await supabase
            .from('attendance')
            .delete()
            .eq('class_id', classId);

        // Then delete the class
        await supabase
            .from('classes')
            .delete()
            .eq('id', classId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Class "$className" deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        _fetchClasses(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting class: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _updateClassName(String classId, String currentName) async {
    final newNameController = TextEditingController(text: currentName);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Update Class Name',
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: newNameController,
          decoration: InputDecoration(
            labelText: 'Class Name',
            labelStyle: GoogleFonts.dmSans(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
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
            onPressed: () async {
              final newName = newNameController.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                try {
                  await supabase
                      .from('classes')
                      .update({'name': newName})
                      .eq('id', classId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Class name updated to "$newName"'),
                      backgroundColor: AppColors.success,
                    ),
                  );

                  Navigator.pop(context);
                  _fetchClasses(); // Refresh the list
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error updating class: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ Please enter a different class name'),
                    backgroundColor: AppColors.warning,
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

  void _showClassOptions(BuildContext context, Map<String, dynamic> classItem) {
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
              classItem['name'],
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${classItem['student_count']} students',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            
            // View Attendance Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassAttendancePage(
                        classId: classItem['id'],
                        className: classItem['name'],
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.calendar_today, size: 20),
                label: Text(
                  'View Attendance',
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
            
            // Update Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _updateClassName(classItem['id'], classItem['name']);
                },
                icon: Icon(Icons.edit, size: 20),
                label: Text(
                  'Edit Class Name',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
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
                  _deleteClass(classItem['id'], classItem['name']);
                },
                icon: Icon(Icons.delete, size: 20, color: AppColors.error),
                label: Text(
                  'Delete Class',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("List of Classes"),
        backgroundColor: AppColors.appBar,

        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.class_,
                        size: 64,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No classes available",
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create your first class to get started",
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
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final classItem = _classes[index];
                    return Card(
                      color: AppColors.surface,
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.class_,
                              color: AppColors.textOnPrimary),
                        ),
                        title: Text(
                          classItem['name'] ?? "Unnamed Class",
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          "Students: ${classItem['student_count']}",
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary, 
                            fontSize: 14
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.more_vert, color: AppColors.primary),
                          onPressed: () => _showClassOptions(context, classItem),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClassAttendancePage(
                                classId: classItem['id'],
                                className: classItem['name'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateClassScreen()),
          ).then((_) => _fetchClasses());
        },
        backgroundColor: AppColors.buttonPrimary,
        child: const Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
    );
  }
}