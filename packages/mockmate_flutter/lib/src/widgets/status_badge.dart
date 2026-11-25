import 'package:flutter/material.dart';
import 'package:mockmate_flutter/src/theme/inspector_theme.dart';

/// Badge displaying HTTP method with distinctive color.
class HttpMethodBadge extends StatelessWidget {
  const HttpMethodBadge({
    super.key,
    required this.method,
    this.fontSize = 11,
  });

  final String method;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = MockMateTheme.getMethodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Badge displaying HTTP status code.
class StatusCodeBadge extends StatelessWidget {
  const StatusCodeBadge({
    super.key,
    required this.statusCode,
    this.statusMessage,
  });

  final int statusCode;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final color = MockMateTheme.getStatusColor(statusCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        statusCode > 0 ? '$statusCode' : 'ERR',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
