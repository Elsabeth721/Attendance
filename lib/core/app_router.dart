
import 'package:attendance_management_system/features/screen/superadmin_screen/home.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const superAdminHome ='/super-admin-home';

  static Route<dynamic> generateRoute(RouteSettings settings){
    switch (settings.name){
      case superAdminHome:
        return MaterialPageRoute(builder: (_)=> const SuperAdminHomePage() );
      default: 
        return MaterialPageRoute(
          builder: (_)=> Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),);
    }
  }
}