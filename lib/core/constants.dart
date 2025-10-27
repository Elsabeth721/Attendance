// If this file shouldn't depend on Material widgets, import dart:ui:
import 'dart:ui' show Color; 
// (Alternatively, you can use: import 'package:flutter/material.dart';)

class Role {
  static const String superAdmin = 'superadmin';
  static const String admin = 'admin';
}

class AppColors {
  AppColors._(); // no instances

  // Brand
  // static const Color primary = Color(0xFF0066CC);
  static const Color primary = Color(0xFF2071B3);
  static const Color primaryLight = Color.fromARGB(255, 55, 120, 174);
  static const Color primaryDark = Color(0xFF004C99);

  // Secondary / Accent
  static const Color secondary = Color(0xFFFFA500);
  static const Color secondaryLight = Color(0xFFFFC04D);
  static const Color secondaryDark = Color.fromARGB(255, 210, 164, 77);

  // Surfaces & Backgrounds
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color appBar = primary;

  // Text
  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF1C1C1C);

  // Buttons & States
  static const Color buttonPrimary = primary;
  static const Color buttonSecondary = Color(0xFF03DAC6);
  static const Color buttonDisabled = Color(0xFFB0BEC5);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color.fromARGB(255, 164, 72, 49);
  static const Color info = Color(0xFF29B6F6);

  // Lines & Shadows
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);
  static const Color shadow = Color(0x1A000000); // 10% black
}
