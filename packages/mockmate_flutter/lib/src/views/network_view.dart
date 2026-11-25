import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';

/// Interactive network condition simulator controls.
class NetworkView extends StatefulWidget {
  const NetworkView({super.key, required this.mockMate});

  final MockMate mockMate;

  @override
  State<NetworkView> createState() => _NetworkViewState();
}

class _NetworkViewState extends State<NetworkView> {
  late NetworkProfile _profile;
  late bool _simulationEnabled;

  @override
  void initState() {
    super.initState();
    _profile = widget.mockMate.network.profile;
    _simulationEnabled = widget.mockMate.network.isEnabled;
  }

  void _updateProfile(NetworkProfile profile) {
    setState(() {
      _profile = profile;
      widget.mockMate.network.setProfile(profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final presets = [
      NetworkProfile.excellent,
      NetworkProfile.good,
      NetworkProfile.average,
      NetworkProfile.poor,
      NetworkProfile.offline,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Network Simulation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _simulationEnabled,
                onChanged: (val) {
                  setState(() {
                    _simulationEnabled = val;
                    widget.mockMate.network.setEnabled(val);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Select Network Profile Preset',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              final isSelected = _profile.name == preset.name;
              return ChoiceChip(
                label: Text(preset.displayName),
                selected: isSelected,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onSelected: (val) {
                  if (val) _updateProfile(preset);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Custom Fine-tuning',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Offline mode toggle
          SwitchListTile(
            title: const Text('Offline Mode'),
            subtitle: const Text(
                'Simulates total lack of connectivity (connection rejected)'),
            value: _profile.isOffline,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              _updateProfile(_profile.copyWith(isOffline: val));
            },
          ),
          const SizedBox(height: 8),
          // Min Latency
          Text('Minimum Latency: ${_profile.minLatency.inMilliseconds} ms'),
          Slider(
            min: 0,
            max: 3000,
            divisions: 60,
            value: _profile.minLatency.inMilliseconds.toDouble(),
            onChanged: (val) {
              final newMin = Duration(milliseconds: val.round());
              final newMax =
                  _profile.maxLatency < newMin ? newMin : _profile.maxLatency;
              _updateProfile(
                  _profile.copyWith(minLatency: newMin, maxLatency: newMax));
            },
          ),
          // Max Latency
          Text('Maximum Latency: ${_profile.maxLatency.inMilliseconds} ms'),
          Slider(
            min: 0,
            max: 5000,
            divisions: 100,
            value: _profile.maxLatency.inMilliseconds.toDouble(),
            onChanged: (val) {
              final newMax = Duration(milliseconds: val.round());
              final newMin =
                  _profile.minLatency > newMax ? newMax : _profile.minLatency;
              _updateProfile(
                  _profile.copyWith(minLatency: newMin, maxLatency: newMax));
            },
          ),
          // Failure Rate
          Text(
              'Failure Probability: ${(_profile.failureRate * 100).toStringAsFixed(1)} %'),
          Slider(
            min: 0,
            max: 1.0,
            divisions: 20,
            value: _profile.failureRate,
            onChanged: (val) {
              _updateProfile(_profile.copyWith(failureRate: val));
            },
          ),
        ],
      ),
    );
  }
}
