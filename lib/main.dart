// import 'package:attendance_management_system/core/constants.dart';
// import 'package:attendance_management_system/features/screen/login.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url: 'https://doauykteqlpnxzcjkkht.supabase.co',
//     anonKey:
//         'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvYXV5a3RlcWxwbnh6Y2pra2h0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzNjU1MDMsImV4cCI6MjA3MTk0MTUwM30.3EruISh1N_xWZ_ObPUoMTg6WgEdDkoea5KZAk_dBT_c',
//         authOptions: const FlutterAuthClientOptions(
//     autoRefreshToken: true,
//     // persistSession: true,
//   ),
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Attendance Management System',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const HomePage(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Circular Image
//                 CircleAvatar(
//                   radius: 60,
//                   backgroundColor: AppColors.primaryLight,
//                   backgroundImage: const AssetImage(
//                     'assets/logo.jpg',
//                   ),
//                 ),
//                 const SizedBox(height: 50),

//                 // Title
//                 Text(
//                   'Fre Haymanot\nAttendance Management System',
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.primaryDark,
//                       ),
//                 ),
//                 const SizedBox(height: 20),

//                 // Subtitle
//                 Text(
//                   'Welcome! Please log in to continue',
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                         color: AppColors.textOnPrimary,
//                       ),
//                 ),
//                 const SizedBox(height: 40),

//                 // Login Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (_) => const LoginPage()),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.buttonPrimary,
//                       foregroundColor: AppColors.textSecondary,
//                       padding: const EdgeInsets.symmetric(
//                           vertical: 16, horizontal: 24),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 3,
//                     ),
//                     child: const Text(
//                       'Login',
//                       style: TextStyle(
//                         color: AppColors.textOnPrimary,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


// // class LoginPage extends StatefulWidget {
// //   const LoginPage({super.key});

// //   @override
// //   State<LoginPage> createState() => _LoginPageState();
// // }

// // class _LoginPageState extends State<LoginPage> {
// //   final TextEditingController _usernameController = TextEditingController();
// //   final TextEditingController _passwordController = TextEditingController();

// //   Future<void> _login() async {
// //     final response = await Supabase.instance.client
// //         .from('users')
// //         .select()
// //         .eq('username', _usernameController.text)
// //         .eq('password', _passwordController.text)
// //         .maybeSingle();

// //     if (response == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Invalid login')),
// //       );
// //       return;
// //     }

// //     final role = response['role'];
// //     if (role == 'superadmin') {
// //       Navigator.pushReplacement(
// //         context,
// //         MaterialPageRoute(builder: (_) => const SuperAdminHomePage()),
// //       );
// //     } else if (role == 'admin') {
//       // Navigator.pushReplacement(
//       //   context,
//       //   MaterialPageRoute(builder: (_) => const AdminHomePage()),
//       // );
// //     } 
// //     else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Unknown role')),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Padding(
// //         padding: const EdgeInsets.all(24.0),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
// //             TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
// //             const SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: _login,
// //               child: const Text('Login'),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
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