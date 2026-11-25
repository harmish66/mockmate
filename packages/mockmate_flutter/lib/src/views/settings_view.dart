import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mockmate/mockmate.dart';

/// Settings, data clearing, export, and redaction management.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key, required this.mockMate});

  final MockMate mockMate;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final isRecording = widget.mockMate.recorder.isRecording;
    final redactionRules = widget.mockMate.recorder.redactionRules;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recorder Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Capture Traffic'),
            subtitle: const Text(
                'When enabled, incoming mock requests are recorded for inspection and replay.'),
            value: isRecording,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                if (val) {
                  widget.mockMate.recorder.start();
                } else {
                  widget.mockMate.recorder.stop();
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear Request History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  widget.mockMate.recorder.clear();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recorded history cleared')),
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export History JSON'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final jsonStr = widget.mockMate.recorder.exportJson();
                  Clipboard.setData(ClipboardData(text: jsonStr));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Exported history JSON copied to clipboard')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Sensitive Data Redaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'MockMate automatically redacts sensitive credentials from headers and request/response payloads before saving or displaying in the inspector.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          const Text('Redacted Headers:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: redactionRules.sensitiveHeaders.map((h) {
              return Chip(
                label: Text(h, style: const TextStyle(fontSize: 11)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Redacted Body Keys:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: redactionRules.sensitiveBodyKeys.map((k) {
              return Chip(
                label: Text(k, style: const TextStyle(fontSize: 11)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
