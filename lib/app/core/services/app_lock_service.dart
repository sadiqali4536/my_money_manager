import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  static const String _keyAppLockEnabled = 'app_lock_enabled_flag';
  static const String _keyPinHash = 'app_lock_pin_hash';
  static const String _keyPinSalt = 'app_lock_pin_salt';

  final FlutterSecureStorage _storage;
  final GetStorage _fallbackStorage;
  final LocalAuthentication _localAuth;

  AppLockService({
    FlutterSecureStorage? storage,
    GetStorage? fallbackStorage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            ),
        _fallbackStorage = fallbackStorage ?? GetStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Check whether App Lock is enabled
  Future<bool> isAppLockEnabled() async {
    try {
      final value = await _readValue(_keyAppLockEnabled);
      if (value == 'true') {
        final hash = await _readValue(_keyPinHash);
        return hash != null && hash.isNotEmpty;
      }
      return false;
    } catch (e) {
      debugPrint("isAppLockEnabled error: $e");
      return false;
    }
  }

  /// Write value trying SecureStorage first, falling back to GetStorage
  Future<void> _writeValue(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint("FlutterSecureStorage write failed, falling back to GetStorage: $e");
    }
    // Also persist in GetStorage as reliable backup
    await _fallbackStorage.write(key, value);
  }

  /// Read value trying SecureStorage first, falling back to GetStorage
  Future<String?> _readValue(String key) async {
    try {
      final val = await _storage.read(key: key);
      if (val != null && val.isNotEmpty) {
        return val;
      }
    } catch (e) {
      debugPrint("FlutterSecureStorage read failed, falling back to GetStorage: $e");
    }
    final fallbackVal = _fallbackStorage.read<String>(key);
    return fallbackVal;
  }

  /// Delete value from both storages
  Future<void> _deleteValue(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint("FlutterSecureStorage delete error: $e");
    }
    await _fallbackStorage.remove(key);
  }

  /// Generate a cryptographically secure random salt
  String _generateSalt([int length = 32]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// Compute salted SHA-256 hash
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin:$salt');
    return sha256.convert(bytes).toString();
  }

  /// Set and enable a new 4-digit PIN
  Future<bool> setPin(String pin) async {
    if (pin.length != 4) return false;
    try {
      final salt = _generateSalt();
      final hash = _hashPin(pin, salt);

      await _writeValue(_keyPinSalt, salt);
      await _writeValue(_keyPinHash, hash);
      await _writeValue(_keyAppLockEnabled, 'true');
      return true;
    } catch (e, stack) {
      debugPrint("Error in setPin: $e\n$stack");
      return false;
    }
  }

  /// Verify entered PIN against stored salted hash
  Future<bool> verifyPin(String pin) async {
    if (pin.length != 4) return false;
    try {
      final salt = await _readValue(_keyPinSalt);
      final storedHash = await _readValue(_keyPinHash);
      if (salt == null || storedHash == null) return false;

      final calculatedHash = _hashPin(pin, salt);
      return calculatedHash == storedHash;
    } catch (e) {
      debugPrint("Error in verifyPin: $e");
      return false;
    }
  }

  /// Authenticate using device biometrics or credentials for Forgot PIN
  Future<bool> authenticateBiometricsOrCredentials({
    String reason = 'Authenticate to reset your 4-digit App Lock PIN',
  }) async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck && !isDeviceSupported) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }

  /// Disable App Lock and delete secure storage entries
  Future<void> disableAppLock() async {
    try {
      await _deleteValue(_keyAppLockEnabled);
      await _deleteValue(_keyPinHash);
      await _deleteValue(_keyPinSalt);
    } catch (e) {
      debugPrint("Error disabling app lock: $e");
    }
  }
}

