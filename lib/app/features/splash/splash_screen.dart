import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/app_lock_controller.dart';
import '../app_lock/app_lock_screen.dart';
import '../main_navigation/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _animController.forward();

    // Smooth navigation after splash display
    Timer(const Duration(milliseconds: 2400), () async {
      if (mounted) {
        final lockController = AppLockController.to;
        await lockController.loadLockStatus();

        if (lockController.isAppLockEnabled.value) {
          // Navigate to MainNavigationScreen first, then immediately overlay AppLockScreen
          // without displaying main content briefly
          Get.offAll(
            () => const MainNavigationScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 300),
          );
          lockController.isLocked.value = true;
          Get.to(
            () => const AppLockScreen(),
            fullscreenDialog: true,
            transition: Transition.noTransition,
          );
        } else {
          Get.off(
            () => const MainNavigationScreen(),
            transition: Transition.fadeIn,
            duration: const Duration(milliseconds: 600),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated Logo
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/logo_my_money_manager.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'my money manager',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Color(0xFF1E232A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Smart budgeting & envelope wealth tracking',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

