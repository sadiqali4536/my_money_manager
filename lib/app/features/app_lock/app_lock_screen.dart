import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/controllers/app_lock_controller.dart';
import 'set_pin_screen.dart';
import 'widgets/numeric_keypad.dart';

class AppLockScreen extends StatefulWidget {
  final bool isDisablingMode;

  const AppLockScreen({super.key, this.isDisablingMode = false});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isError = false;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        if (_isError) {
          _isError = false;
          _errorMessage = null;
        }
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _isError = false;
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    final controller = AppLockController.to;
    final isCorrect = await controller.verifyEnteredPin(_enteredPin);

    if (isCorrect) {
      if (widget.isDisablingMode) {
        // Return true to caller (handleToggle in Settings/Profile)
        Get.back(result: true);
      } else {
        // Unlocked!
        if (mounted && Navigator.of(context).canPop()) {
          Get.back();
        }
      }
    } else {
      setState(() {
        _isError = true;
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  Future<void> _handleForgotPin() async {
    final controller = AppLockController.to;
    final authenticated = await controller
        .authenticateBiometricsOrCredentials();

    if (authenticated) {
      // Allowed to reset PIN
      Get.to(() => const SetPinScreen(isResetMode: true));
    } else {
      Get.snackbar(
        'Authentication Failed',
        'Could not verify identity via device biometrics/credentials.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E232A),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget
          .isDisablingMode, // Lock screen cannot be dismissed via back button
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Column(
            children: [
              if (widget.isDisablingMode)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF082B63),
                    ),
                    onPressed: () => Get.back(result: false),
                  ),
                )
              else
                const SizedBox(height: 36),

              // My Money Manager Branding & Lock Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFF082B63), // Navy Blue
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF082B63).withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: Color(0xFFD4F938), // Yellow / Neon Lime accent
                ),
              ),
              const SizedBox(height: 16),

              // Branding Name
              const Text(
                'My Money Manager',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),

              // Greeting & Description
              Text(
                widget.isDisablingMode ? 'Verify PIN' : 'Welcome Back!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF082B63),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.isDisablingMode
                      ? 'Enter your 4-digit PIN to disable App Lock.'
                      : 'Enter your 4-digit PIN to unlock the app.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // PIN Dots Indicator
              PinDotsIndicator(
                pinLength: _enteredPin.length,
                isError: _isError,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),

              // Numeric Keypad
              NumericKeypad(
                onKeyPressed: _onDigitPressed,
                onBackspace: _onBackspace,
                showForgotPin: !widget.isDisablingMode,
                onForgotPin: _handleForgotPin,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
