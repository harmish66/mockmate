import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/src/views/dashboard_view.dart';
import 'package:mockmate_flutter/src/views/network_view.dart';
import 'package:mockmate_flutter/src/views/replay_view.dart';
import 'package:mockmate_flutter/src/views/requests_view.dart';
import 'package:mockmate_flutter/src/views/scenarios_view.dart';
import 'package:mockmate_flutter/src/views/settings_view.dart';

/// Full developer inspection dialog / page.
class MockMateInspectorDialog extends StatefulWidget {
  const MockMateInspectorDialog({
    super.key,
    required this.mockMate,
    this.initialIndex = 0,
  });

  final MockMate mockMate;
  final int initialIndex;

  /// Opens the MockMate inspector modal.
  static Future<void> show(BuildContext context,
      {required MockMate mockMate, int initialIndex = 0}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => MockMateInspectorDialog(
          mockMate: mockMate, initialIndex: initialIndex),
    );
  }

  @override
  State<MockMateInspectorDialog> createState() =>
      _MockMateInspectorDialogState();
}

class _MockMateInspectorDialogState extends State<MockMateInspectorDialog> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;

    final pages = [
      DashboardView(
        mockMate: widget.mockMate,
        onNavigateToRequests: () => setState(() => _selectedIndex = 1),
        onNavigateToScenarios: () => setState(() => _selectedIndex = 2),
      ),
      RequestsView(mockMate: widget.mockMate),
      ScenariosView(mockMate: widget.mockMate),
      NetworkView(mockMate: widget.mockMate),
      ReplayView(mockMate: widget.mockMate),
      SettingsView(mockMate: widget.mockMate),
    ];

    const destinations = [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.swap_horiz_outlined),
        selectedIcon: Icon(Icons.swap_horiz),
        label: Text('Requests'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.alt_route_outlined),
        selectedIcon: Icon(Icons.alt_route),
        label: Text('Scenarios'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.wifi_outlined),
        selectedIcon: Icon(Icons.wifi),
        label: Text('Network'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.replay_outlined),
        selectedIcon: Icon(Icons.replay),
        label: Text('Replay'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];

    Widget body;
    if (isDesktop) {
      body = Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (val) =>
                setState(() => _selectedIndex = val),
            destinations: destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_selectedIndex]),
        ],
      );
    } else {
      body = Column(
        children: [
          Expanded(child: pages[_selectedIndex]),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (val) =>
                setState(() => _selectedIndex = val),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.dashboard), label: 'Dashboard'),
              NavigationDestination(
                  icon: Icon(Icons.swap_horiz), label: 'Requests'),
              NavigationDestination(
                  icon: Icon(Icons.alt_route), label: 'Scenarios'),
              NavigationDestination(icon: Icon(Icons.wifi), label: 'Network'),
              NavigationDestination(icon: Icon(Icons.replay), label: 'Replay'),
              NavigationDestination(
                  icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ],
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 850),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('MockMate Inspector',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: body,
        ),
      ),
    );
  }
}
