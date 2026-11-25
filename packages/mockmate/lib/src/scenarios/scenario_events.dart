/// Event fired when scenario state changes.
class ScenarioChangeEvent {
  const ScenarioChangeEvent({
    required this.previousScenario,
    required this.newScenario,
    this.routeName,
    required this.timestamp,
  });

  final String? previousScenario;
  final String? newScenario;
  final String? routeName;
  final DateTime timestamp;

  bool get isGlobal => routeName == null;

  @override
  String toString() {
    if (isGlobal) {
      return 'Global scenario changed from $previousScenario to $newScenario at $timestamp';
    }
    return 'Route "$routeName" scenario changed from $previousScenario to $newScenario at $timestamp';
  }
}
