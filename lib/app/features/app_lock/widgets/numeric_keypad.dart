import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onForgotPin;
  final bool showForgotPin;

  const NumericKeypad({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.onForgotPin,
    this.showForgotPin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((val) => _buildNumberButton(val)).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: () => onKeyPressed(number),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF082B63), // Navy Blue
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Left action (Forgot PIN or empty spacer)
        SizedBox(
          width: 72,
          height: 72,
          child: showForgotPin && onForgotPin != null
              ? Center(
                  child: TextButton(
                    onPressed: onForgotPin,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(72, 72),
                    ),
                    child: const Text(
                      'Forgot\nPIN?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF082B63),
                        height: 1.2,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // 0 key
        _buildNumberButton('0'),

        // Backspace key
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(36),
              onTap: onBackspace,
              child: const Center(
                child: Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: Color(0xFF082B63),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PinDotsIndicator extends StatelessWidget {
  final int pinLength;
  final int maxLength;
  final bool isError;

  const PinDotsIndicator({
    super.key,
    required this.pinLength,
    this.maxLength = 4,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilled = index < pinLength;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 20 : 16,
          height: isFilled ? 20 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isError
                ? AppColors.expense
                : isFilled
                    ? const Color(0xFF082B63) // Navy Blue
                    : const Color(0xFFCBD5E1),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: (isError ? AppColors.expense : const Color(0xFF082B63))
                          .withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isError
                  ? AppColors.expense
                  : isFilled
                      ? const Color(0xFF082B63)
                      : const Color(0xFF94A3B8),
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

