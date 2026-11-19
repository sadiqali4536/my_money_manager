import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import 'confirm_pin_screen.dart';
import 'widgets/numeric_keypad.dart';

class SetPinScreen extends StatefulWidget {
  final bool isResetMode;

  const SetPinScreen({super.key, this.isResetMode = false});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _enteredPin = '';

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        final pinToConfirm = _enteredPin;
        // Small delay for smooth visual feedback of 4th dot
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            Get.to(() => ConfirmPinScreen(
                  initialPin: pinToConfirm,
                  isResetMode: widget.isResetMode,
                ));
          }
        });
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF082B63)),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Lock icon badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF082B63), // Navy Blue
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF082B63).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 36, color: Color(0xFFD4F938)),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isResetMode ? 'Reset 4-Digit PIN' : 'Create a 4-digit PIN',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF082B63),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This PIN will be required to unlock My Money Manager.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // PIN Dots Indicator
            PinDotsIndicator(pinLength: _enteredPin.length),

            const Spacer(),

            // Numeric Keypad
            NumericKeypad(
              onKeyPressed: _onDigitPressed,
              onBackspace: _onBackspace,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

