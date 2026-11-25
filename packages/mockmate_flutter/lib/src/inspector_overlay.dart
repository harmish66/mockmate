import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/src/mockmate_inspector_dialog.dart';

/// Floating overlay button to launch the MockMate Inspector.
/// Only shown when [enabled] is true (defaults to [kDebugMode] to prevent production exposure).
class MockMateInspectorOverlay extends StatefulWidget {
  const MockMateInspectorOverlay({
    super.key,
    required this.child,
    required this.mockMate,
    this.enabled = kDebugMode,
  });

  final Widget child;
  final MockMate mockMate;
  final bool enabled;

  @override
  State<MockMateInspectorOverlay> createState() =>
      _MockMateInspectorOverlayState();
}

class _MockMateInspectorOverlayState extends State<MockMateInspectorOverlay> {
  Offset _position = const Offset(20, 80);

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position += details.delta;
              });
            },
            child: Material(
              color: Colors.transparent,
              child: FloatingActionButton.small(
                heroTag: 'mockmate_debug_button',
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: const Color(0xFF38BDF8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFF334155)),
                ),
                tooltip: 'Open MockMate Inspector',
                onPressed: () {
                  MockMateInspectorDialog.show(context,
                      mockMate: widget.mockMate);
                },
                child: const Icon(Icons.bug_report, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
