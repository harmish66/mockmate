import 'package:flutter/material.dart';

/// Styling and color constants for the MockMate developer inspector.
class MockMateTheme {
  // Method colors
  static const Color methodGet = Color(0xFF2563EB); // Blue
  static const Color methodPost = Color(0xFF059669); // Green
  static const Color methodPut = Color(0xFFD97706); // Amber
  static const Color methodPatch = Color(0xFF0D9488); // Teal
  static const Color methodDelete = Color(0xFFDC2626); // Red
  static const Color methodHead = Color(0xFF7C3AED); // Indigo
  static const Color methodOptions = Color(0xFF4B5563); // Gray

  // Status colors
  static const Color statusSuccess = Color(0xFF10B981);
  static const Color statusRedirect = Color(0xFF3B82F6);
  static const Color statusClientError = Color(0xFFF59E0B);
  static const Color statusServerError = Color(0xFFEF4444);

  // Backgrounds & accents
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  /// Method badge background color.
  static Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return methodGet;
      case 'POST':
        return methodPost;
      case 'PUT':
        return methodPut;
      case 'PATCH':
        return methodPatch;
      case 'DELETE':
        return methodDelete;
      case 'HEAD':
        return methodHead;
      case 'OPTIONS':
        return methodOptions;
      default:
        return methodOptions;
    }
  }

  /// Status code badge color.
  static Color getStatusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return statusSuccess;
    if (statusCode >= 300 && statusCode < 400) return statusRedirect;
    if (statusCode >= 400 && statusCode < 500) return statusClientError;
    return statusServerError;
  }
}
