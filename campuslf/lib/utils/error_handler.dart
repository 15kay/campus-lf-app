import 'package:flutter/material.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String getFirebaseErrorMessage(String error) {
    if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    }
    if (error.contains('user-not-found')) {
      return 'User not found. Please check your email.';
    }
    if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (error.contains('email-already-in-use')) {
      return 'Email already registered. Please sign in instead.';
    }
    if (error.contains('weak-password')) {
      return 'Password too weak. Use at least 6 characters.';
    }
    return 'An error occurred. Please try again.';
  }
}