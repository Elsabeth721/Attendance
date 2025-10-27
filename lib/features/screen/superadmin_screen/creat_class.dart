import 'package:attendance_management_system/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final TextEditingController _nameController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isCreating = false;

  Future<void> _createClass() async {
    try {
      final className = _nameController.text.trim();
      
      // Validate class name
      if (className.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please enter a class name",
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Check if class name already exists (case insensitive and trimmed)
      final existingClasses = await supabase
          .from('classes')
          .select('name')
          .ilike('name', className);

      if (existingClasses.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Class '$className' already exists",
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      setState(() => _isCreating = true);

      final user = supabase.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "You must be logged in to create a class",
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isCreating = false);
        return;
      }

      // Create the class
      await supabase.from('classes').insert({
        'name': className,
        'created_by': user.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Class '$className' created successfully",
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e, stack) {
      debugPrint("❌ Error creating class: $e");
      debugPrint("📌 Stack trace: $stack");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error creating class: ${e.toString()}",
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textOnPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Create Class",
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Enter Class Details",
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Class Name Input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Class Name',
                labelStyle: GoogleFonts.dmSans(),
                hintText: 'e.g., Grade 7',
                hintStyle: GoogleFonts.dmSans(
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
                prefixIcon: const Icon(Icons.class_, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Class names must be unique. Extra spaces will be automatically trimmed.",
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createClass,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: _isCreating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Creating...",
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        "Create Class",
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isCreating ? null : () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}