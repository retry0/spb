import 'package:flutter/services.dart';

class UsernameValidator {
  static const int minLength = 3;
  static const int maxLength = 20;
  
  // Allowed characters: letters, numbers, underscore, hyphen
  static final RegExp _validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');

  /// Validates username format and returns error message if invalid
  static String? validateFormat(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }

    if (username.length < minLength) {
      return 'Username must be at least $minLength characters long';
    }

    if (username.length > maxLength) {
      return 'Username must be no more than $maxLength characters long';
    }

    if (!_validPattern.hasMatch(username)) {
      return 'Username can only contain letters, numbers, underscore, and hyphen';
    }

    return null; // Valid username
  }

  /// Normalizes username by converting to lowercase and trimming
  static String normalize(String username) {
    return username.toLowerCase().trim();
  }

  /// Checks if username is available (format validation only)
  static bool isValidFormat(String username) {
    return validateFormat(username) == null;
  }

  /// Creates a text input formatter for username fields
  static List<TextInputFormatter> getInputFormatters() {
    return [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
      LengthLimitingTextInputFormatter(maxLength),
      LowerCaseTextFormatter(),
    ];
  }
}

/// Custom text formatter to convert input to lowercase
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}