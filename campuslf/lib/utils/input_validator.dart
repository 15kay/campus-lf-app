class InputValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@(wsu\.ac\.za|mywsu\.ac\.za)$').hasMatch(email)) {
      return 'Must use WSU email address';
    }
    return null;
  }

  static String? validateText(String? text, {int maxLength = 500}) {
    if (text == null || text.trim().isEmpty) return 'This field is required';
    if (text.length > maxLength) return 'Text too long (max $maxLength characters)';
    return null;
  }

  static String sanitizeText(String text) {
    // Remove angle brackets and quotes to avoid HTML/script injection in free text inputs.
    // Use a standard (non-raw) string so quotes are properly escaped in Dart.
    return text.trim().replaceAll(RegExp("[<>\"']"), '');
  }
}