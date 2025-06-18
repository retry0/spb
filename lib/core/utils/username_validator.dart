import 'package:flutter/services.dart';

class UserNameValidator {
  static const int minLength = 3;
  static const int maxLength = 20;

  // Allowed characters: letters, numbers, underscore, hyphen
  static final RegExp _validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');

  /// Validates userName format and returns error message if invalid
  static String? validateFormat(String? userName) {
    if (userName == null || userName.isEmpty) {
      return 'Username is required';
    }

    if (userName.length < minLength) {
      return 'Username must be at least $minLength characters long';
    }

    if (userName.length > maxLength) {
      return 'Username must be no more than $maxLength characters long';
    }

    if (!_validPattern.hasMatch(userName)) {
      return 'Username can only contain letters, numbers, underscore, and hyphen';
    }

    return null; // Valid userName
  }

  /// Normalizes userName by converting to lowercase and trimming
  static String normalize(String userName) {
    return userName.toLowerCase().trim();
  }

  /// Checks if userName is available (format validation only)
  static bool isValidFormat(String userName) {
    return validateFormat(userName) == null;
  }

  /// Creates a text input formatter for userName fields
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
