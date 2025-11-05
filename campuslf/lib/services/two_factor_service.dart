import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class TwoFactorService {
  static const String _twoFactorEnabledKey = 'two_factor_enabled';
  static const String _backupCodesKey = 'backup_codes';
  static const String _lastCodeKey = 'last_verification_code';
  static const String _codeTimestampKey = 'code_timestamp';

  // Check if 2FA is enabled
  static Future<bool> isTwoFactorEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_twoFactorEnabledKey) ?? false;
  }

  // Enable 2FA
  static Future<List<String>> enableTwoFactor() async {
    final prefs = await SharedPreferences.getInstance();
    final backupCodes = _generateBackupCodes();
    
    await prefs.setBool(_twoFactorEnabledKey, true);
    await prefs.setStringList(_backupCodesKey, backupCodes);
    
    return backupCodes;
  }

  // Disable 2FA
  static Future<void> disableTwoFactor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoFactorEnabledKey, false);
    await prefs.remove(_backupCodesKey);
    await prefs.remove(_lastCodeKey);
    await prefs.remove(_codeTimestampKey);
  }

  // Generate verification code (simulates SMS/Email)
  static Future<String> generateVerificationCode() async {
    final code = _generateSixDigitCode();
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_lastCodeKey, code);
    await prefs.setInt(_codeTimestampKey, DateTime.now().millisecondsSinceEpoch);
    
    return code;
  }

  // Verify code
  static Future<bool> verifyCode(String inputCode) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCode = prefs.getString(_lastCodeKey);
    final timestamp = prefs.getInt(_codeTimestampKey);
    
    if (storedCode == null || timestamp == null) return false;
    
    // Check if code is expired (5 minutes)
    final codeAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (codeAge > 300000) return false; // 5 minutes in milliseconds
    
    return storedCode == inputCode;
  }

  // Verify backup code
  static Future<bool> verifyBackupCode(String inputCode) async {
    final prefs = await SharedPreferences.getInstance();
    final backupCodes = prefs.getStringList(_backupCodesKey) ?? [];
    
    if (backupCodes.contains(inputCode)) {
      // Remove used backup code
      backupCodes.remove(inputCode);
      await prefs.setStringList(_backupCodesKey, backupCodes);
      return true;
    }
    
    return false;
  }

  // Get remaining backup codes
  static Future<List<String>> getBackupCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_backupCodesKey) ?? [];
  }

  // Generate new backup codes
  static Future<List<String>> regenerateBackupCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final newCodes = _generateBackupCodes();
    await prefs.setStringList(_backupCodesKey, newCodes);
    return newCodes;
  }

  // Private helper methods
  static String _generateSixDigitCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  static List<String> _generateBackupCodes() {
    final random = Random();
    final codes = <String>[];
    
    for (int i = 0; i < 10; i++) {
      final code = (10000000 + random.nextInt(90000000)).toString();
      codes.add('${code.substring(0, 4)}-${code.substring(4)}');
    }
    
    return codes;
  }
}