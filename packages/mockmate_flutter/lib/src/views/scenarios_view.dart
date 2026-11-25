import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';

/// Management interface for global and route scenarios.
class ScenariosView extends StatefulWidget {
  const ScenariosView({super.key, required this.mockMate});

  final MockMate mockMate;

  @override
  State<ScenariosView> createState() => _ScenariosViewState();
}

class _ScenariosViewState extends State<ScenariosView> {
  @override
  Widget build(BuildContext context) {
    final activeGlobal = widget.mockMate.scenarioManager.activeGlobalScenario;
    final definitions = widget.mockMate.scenarioManager.definitions;
    final routeScenarios = widget.mockMate.scenarioManager.routeActiveScenarios;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Global Scenario',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the active global scenario to apply across all endpoints by default.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ScenarioNames.allStandard.map((name) {
              final isSelected = activeGlobal == name;
              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      widget.mockMate.activateScenario(name);
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Route Scenario Overrides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (routeScenarios.isNotEmpty)
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset Overrides'),
                  onPressed: () {
                    setState(() {
                      widget.mockMate.scenarioManager.resetAll();
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (definitions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No route-specific scenarios defined yet.\nUse mockMate.scenario(name, {...}) to define scenarios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: definitions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final def = definitions.values.elementAt(index);
                final current =
                    routeScenarios[def.name] ?? '(Global: $activeGlobal)';

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(def.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Available: ${def.availableScenarios.join(", ")}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color),
                            ),
                          ],
                        ),
                        DropdownButton<String>(
                          value: def.availableScenarios.contains(current)
                              ? current
                              : null,
                          hint: Text(current),
                          borderRadius: BorderRadius.circular(8),
                          items: def.availableScenarios.map((s) {
                            return DropdownMenuItem<String>(
                              value: s,
                              child: Text(s),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                widget.mockMate
                                    .activateRouteScenario(def.name, val);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
