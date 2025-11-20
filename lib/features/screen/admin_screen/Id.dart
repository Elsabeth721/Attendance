import 'package:attendance_management_system/core/constants.dart';
import 'package:attendance_management_system/features/screen/admin_screen/Id_design.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class IdCardManagementPage extends StatefulWidget {
  const IdCardManagementPage({super.key});

  @override
  State<IdCardManagementPage> createState() => _IdCardManagementPageState();
}

class _IdCardManagementPageState extends State<IdCardManagementPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final response = await supabase
          .from('students')
          .select('''
            id,
            first_name,
            last_name,
            student_id_number,
            photo_url,
            classes(name),
            id_card_issued_date
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _students = (response as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading students: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    
    return _students.where((student) {
      final name = '${student['first_name']} ${student['last_name']}'.toLowerCase();
      final id = student['student_id_number']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) || 
             id.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: student['photo_url'] != null
              ? NetworkImage(student['photo_url'])
              : null,
          child: student['photo_url'] == null
              ? Text(student['first_name'][0])
              : null,
        ),
        title: Text(
          '${student['first_name']} ${student['last_name']}',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'ID: ${student['student_id_number'] ?? 'N/A'} • ${student['classes']?['name'] ?? 'N/A'}',
          style: GoogleFonts.dmSans(),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'design') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IdCardDesignPage(studentId: student['id']),
                ),
              );
            } else if (value == 'print') {
              // Direct print functionality
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'design',
              child: Row(
                children: [
                  Icon(Icons.design_services, size: 20),
                  SizedBox(width: 8),
                  Text('Design ID Card'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print, size: 20),
                  SizedBox(width: 8),
                  Text('Print Directly'),
                ],
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'ID Card Management',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or ID...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                
                // Student List
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      return _buildStudentCard(_filteredStudents[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}