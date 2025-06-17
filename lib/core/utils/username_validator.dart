import 'package:flutter/services.dart';

class UsernameValidator {
  static const int minLength = 3;
  static const int maxLength = 20;
  
  // Allowed characters: letters, numbers, underscore, hyphen
  static final RegExp _validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
  
  // Reserved usernames that cannot be used
  static const Set<String> _reservedUsernames = {
    'admin', 'administrator', 'root', 'system', 'user', 'guest',
    'api', 'www', 'mail', 'email', 'support', 'help', 'info',
    'test', 'demo', 'null', 'undefined', 'anonymous', 'public',
    'private', 'secure', 'auth', 'login', 'logout', 'register',
    'signup', 'signin', 'password', 'reset', 'forgot', 'recovery'
  };

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

    if (username.startsWith('_') || username.startsWith('-')) {
      return 'Username cannot start with underscore or hyphen';
    }

    if (username.endsWith('_') || username.endsWith('-')) {
      return 'Username cannot end with underscore or hyphen';
    }

    if (username.contains('__') || username.contains('--') || username.contains('_-') || username.contains('-_')) {
      return 'Username cannot contain consecutive special characters';
    }

    if (_reservedUsernames.contains(username.toLowerCase())) {
      return 'This username is reserved and cannot be used';
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

  /// Suggests alternative usernames if the desired one is taken
  static List<String> generateAlternatives(String baseUsername) {
    final normalized = normalize(baseUsername);
    final alternatives = <String>[];
    
    // Add numbers
    for (int i = 1; i <= 99; i++) {
      alternatives.add('$normalized$i');
    }
    
    // Add underscores with numbers
    for (int i = 1; i <= 9; i++) {
      alternatives.add('${normalized}_$i');
    }
    
    // Add year suffix
    final currentYear = DateTime.now().year;
    alternatives.add('$normalized$currentYear');
    
    return alternatives.take(10).toList();
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