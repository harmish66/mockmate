import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formatted JSON viewer with one-click copy to clipboard.
class JsonViewerWidget extends StatelessWidget {
  const JsonViewerWidget({
    super.key,
    required this.data,
    this.maxHeight,
  });

  final Object? data;
  final double? maxHeight;

  String _formatJson() {
    if (data == null) return 'null';
    if (data is String) {
      try {
        final decoded = jsonDecode(data as String);
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(decoded);
      } catch (_) {
        return data as String;
      }
    }
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatJson();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Stack(
        children: [
          SelectableText(
            formatted,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.4,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'Copy to clipboard',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: formatted));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied JSON to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (maxHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: SingleChildScrollView(child: content),
      );
    }

    return content;
  }
}
