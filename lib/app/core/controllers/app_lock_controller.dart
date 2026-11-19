import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../services/app_lock_service.dart';
import '../../features/app_lock/app_lock_screen.dart';
import '../../features/app_lock/set_pin_screen.dart';

class AppLockController extends GetxController with WidgetsBindingObserver {
  static AppLockController get to => Get.find<AppLockController>();

  final AppLockService _lockService = AppLockService();

  final RxBool isAppLockEnabled = false.obs;
  final RxBool isLocked = false.obs;
  final RxBool isVerifyingOrSettingPin = false.obs;
  DateTime? _lastPausedTime;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadLockStatus();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Load whether App Lock is enabled in secure storage
  Future<void> loadLockStatus() async {
    isAppLockEnabled.value = await _lockService.isAppLockEnabled();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isAppLockEnabled.value) return;

    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      // If returning after being paused and not currently in lock screen or setting PIN
      if (_lastPausedTime != null) {
        final elapsed = DateTime.now().difference(_lastPausedTime!);
        // Lock immediately if backgrounded
        if (elapsed.inMilliseconds > 500) {
          triggerLockIfEnabled();
        }
      }
    }
  }

  /// Lock application if enabled and not already showing lock screen
  void triggerLockIfEnabled() {
    if (!isAppLockEnabled.value) return;
    if (isLocked.value) return; // Already locked
    if (isVerifyingOrSettingPin.value) return; // Currently setting or verifying pin in a flow

    isLocked.value = true;
    Get.to(
      () => const AppLockScreen(),
      fullscreenDialog: true,
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 250),
    );
  }

  /// Set new 4-digit PIN
  Future<bool> saveNewPin(String pin) async {
    final success = await _lockService.setPin(pin);
    if (success) {
      isAppLockEnabled.value = true;
      isLocked.value = false;
    }
    return success;
  }

  /// Verify entered 4-digit PIN
  Future<bool> verifyEnteredPin(String pin) async {
    final ok = await _lockService.verifyPin(pin);
    if (ok) {
      isLocked.value = false;
    }
    return ok;
  }

  /// Biometric / Device credential authentication for Forgot PIN
  Future<bool> authenticateBiometricsOrCredentials() async {
    isVerifyingOrSettingPin.value = true;
    try {
      final authenticated = await _lockService.authenticateBiometricsOrCredentials();
      return authenticated;
    } finally {
      isVerifyingOrSettingPin.value = false;
    }
  }

  /// Disable App Lock
  Future<void> disableAppLock() async {
    await _lockService.disableAppLock();
    isAppLockEnabled.value = false;
    isLocked.value = false;
  }

  /// Handle toggle action from Profile/Settings screen
  Future<void> handleToggle(BuildContext context) async {
    if (!isAppLockEnabled.value) {
      // User is enabling App Lock -> Go to Set PIN Screen
      isVerifyingOrSettingPin.value = true;
      await Get.to(() => const SetPinScreen());
      isVerifyingOrSettingPin.value = false;
    } else {
      // User is turning off App Lock -> Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Disable App Lock',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E232A),
            ),
          ),
          content: const Text(
            'Are you sure you want to disable App Lock?',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Disable'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Require PIN verification before disabling
        isVerifyingOrSettingPin.value = true;
        final verified = await Get.to<bool>(
          () => const AppLockScreen(isDisablingMode: true),
        );
        isVerifyingOrSettingPin.value = false;

        if (verified == true) {
          await disableAppLock();
          Get.snackbar(
            'App Lock Disabled',
            'App Lock has been turned off and PIN removed.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: const Color(0xFF1E232A),
            colorText: Colors.white,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 3),
          );
        }
      }
    }
  }
}

