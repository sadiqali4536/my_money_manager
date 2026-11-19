import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/controllers/app_lock_controller.dart';
import 'widgets/numeric_keypad.dart';

class ConfirmPinScreen extends StatefulWidget {
  final String initialPin;
  final bool isResetMode;

  const ConfirmPinScreen({
    super.key,
    required this.initialPin,
    this.isResetMode = false,
  });

  @override
  State<ConfirmPinScreen> createState() => _ConfirmPinScreenState();
}

class _ConfirmPinScreenState extends State<ConfirmPinScreen> {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isError = false;
  bool _isSaving = false;

  void _onDigitPressed(String digit) {
    if (_isSaving) return;
    if (_enteredPin.length < 4) {
      setState(() {
        if (_isError) {
          _isError = false;
          _errorMessage = null;
        }
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        // Small delay for smooth dot fill animation before saving
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && _enteredPin.length == 4) {
            _verifyAndSave();
          }
        });
      }
    }
  }

  void _onBackspace() {
    if (_isSaving) return;
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _isError = false;
        _errorMessage = null;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyAndSave() async {
    if (_isSaving) return;

    if (_enteredPin.length < 4) {
      setState(() {
        _isError = true;
        _errorMessage = 'Please enter all 4 digits of your PIN.';
      });
      return;
    }

    if (_enteredPin == widget.initialPin) {
      setState(() {
        _isSaving = true;
        _isError = false;
        _errorMessage = null;
      });

      // Matching PIN -> Save securely
      final controller = AppLockController.to;
      final success = await controller.saveNewPin(_enteredPin);

      if (success) {
        if (mounted) {
          // Navigate back first before showing the snackbar so Get.back() does not pop or dispose the snackbar
          if (widget.isResetMode) {
            Get.until((route) => route.isFirst);
          } else {
            Get.back(); // close confirm
            Get.back(); // close set pin
          }

          // Show success snackbar on the destination screen safely
          Get.snackbar(
            'Success',
            'App Lock Enabled Successfully',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF082B63),
            colorText: const Color.fromARGB(
              255,
              255,
              255,
              255,
            ), // Neon lime / Yellow accent
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _isError = true;
            _errorMessage = 'Failed to save PIN. Please try again.';
            _enteredPin = '';
          });
        }
      }
    } else {
      // PINs do not match
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'PINs do not match. Please try again.';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF082B63),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Shield Lock Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF082B63),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF082B63).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 36,
                color: Color(0xFFD4F938),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Confirm your PIN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF082B63),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Re-enter your 4-digit PIN to confirm and activate App Lock.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 36),

            // PIN Dots Indicator
            PinDotsIndicator(pinLength: _enteredPin.length, isError: _isError),

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
            ),
            const SizedBox(height: 20),

            // Explicit Save PIN Button (supports both auto-save & manual tap)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : () => _verifyAndSave(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF082B63),
                    foregroundColor: const Color(0xFFD4F938),
                    disabledBackgroundColor: const Color(
                      0xFF082B63,
                    ).withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFD4F938),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: Color(0xFFD4F938),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Save PIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD4F938),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
