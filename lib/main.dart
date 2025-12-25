import 'package:attendance_management_system/features/screen/splash_screen.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://doauykteqlpnxzcjkkht.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvYXV5a3RlcWxwbnh6Y2pra2h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzNjU1MDMsImV4cCI6MjA3MTk0MTUwM30.3EruISh1N_xWZ_ObPUoMTg6WgEdDkoea5KZAk_dBT_c',
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