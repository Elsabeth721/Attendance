import 'package:attendance_management_system/core/constants.dart';
import 'package:attendance_management_system/features/screen/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SimpleSplashScreen extends StatefulWidget {
  const SimpleSplashScreen({super.key});

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2000), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ScaleTransition(
            scale: _animation,
            child: FadeTransition(
              opacity: _animation,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo Container
                    Image.asset(
                      'assets/attendancefrelogo.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 40),

                    // Title with gradient text
                    _buildGradientTitle(context),
                    const SizedBox(height: 20),

                    // Pulsing dots indicator
                    _buildPulsingDots(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientTitle(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.primaryDark,
              AppColors.buttonPrimary,
            ],
          ).createShader(bounds),
          child: Text(
            'ፍሬ-ሃይማኖት',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Colors.white,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'አቴንዳንስ መቆጣጠሪያ መተግበሪያ',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
                fontSize: 24,
              ),
        ),
      ],
    );
  }

  Widget _buildPulsingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PulsingDot(delay: 0),
        const SizedBox(width: 8),
        _PulsingDot(delay: 200),
        const SizedBox(width: 8),
        _PulsingDot(delay: 400),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final int delay;

  const _PulsingDot({required this.delay});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.buttonPrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}