import 'package:attendance_management_system/features/screen/splash_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dduxsppoekivfqsgkdyu.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRkdXhzcHBvZWtpdmZxc2drZHl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1NDE3MDAsImV4cCI6MjA3NzExNzcwMH0.nyXRB0dqv7GcprfiD-twh6K55x6J7El-Hf3wyRkog-A',
        authOptions: const FlutterAuthClientOptions(
    autoRefreshToken: true,
  ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Management System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SimpleSplashScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}