import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class PasswordSecurity {
  static const int _saltLength = 32;
  static const int _iterations = 100000; // PBKDF2 iterations
  static const int _keyLength = 64; // Output key length in bytes

  /// Generates a cryptographically secure random salt
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64Encode(saltBytes);
  }

  /// Hashes a password using PBKDF2 with SHA-256
  static String hashPassword(String password, String salt) {
    final saltBytes = base64Decode(salt);
    final passwordBytes = utf8.encode(password);
    
    // PBKDF2 implementation
    final hash = _pbkdf2(passwordBytes, saltBytes, _iterations, _keyLength);
    return base64Encode(hash);
  }

  /// Verifies a password against its hash
  static bool verifyPassword(String password, String hash, String salt) {
    final computedHash = hashPassword(password, salt);
    return _constantTimeEquals(computedHash, hash);
  }

  /// PBKDF2 implementation using HMAC-SHA256
  static Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final blocks = (keyLength / 32).ceil();
    final result = <int>[];

    for (int i = 1; i <= blocks; i++) {
      final block = _pbkdf2Block(hmac, salt, iterations, i);
      result.addAll(block);
    }

    return Uint8List.fromList(result.take(keyLength).toList());
  }

  static List<int> _pbkdf2Block(Hmac hmac, List<int> salt, int iterations, int blockIndex) {
    final blockIndexBytes = <int>[
      (blockIndex >> 24) & 0xff,
      (blockIndex >> 16) & 0xff,
      (blockIndex >> 8) & 0xff,
      blockIndex & 0xff,
    ];

    var u = hmac.convert([...salt, ...blockIndexBytes]).bytes;
    final result = List<int>.from(u);

    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  /// Constant-time string comparison to prevent timing attacks
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Validates password strength
  static PasswordStrength validatePasswordStrength(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    int score = 0;
    
    // Length bonus
    if (password.length >= 12) score += 2;
    else if (password.length >= 10) score += 1;
    
    // Character variety
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 2;
    
    // Patterns that reduce strength
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) score -= 1; // Repeated characters
    if (RegExp(r'(012|123|234|345|456|567|678|789|890|abc|bcd|cde)').hasMatch(password.toLowerCase())) score -= 1; // Sequential
    
    if (score >= 6) return PasswordStrength.strong;
    if (score >= 4) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  /// Generates a secure random password
  static String generateSecurePassword({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  String get description {
    switch (this) {
      case PasswordStrength.weak:
        return 'Password is too weak. Use at least 8 characters with mixed case, numbers, and symbols.';
      case PasswordStrength.medium:
        return 'Password strength is acceptable but could be stronger.';
      case PasswordStrength.strong:
        return 'Password is strong and secure.';
    }
  }
}