import 'dart:async';
import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/scenarios/scenario.dart';
import 'package:mockmate/src/scenarios/scenario_events.dart';

/// Manages active scenarios globally and per route/group.
class ScenarioManager {
  ScenarioManager() {
    _streamController = StreamController<ScenarioChangeEvent>.broadcast();
  }

  late final StreamController<ScenarioChangeEvent> _streamController;
  final Map<String, RouteScenarioDefinition> _definitions = {};
  final Map<String, String> _routeActiveScenarios = {};
  String _activeGlobalScenario = ScenarioNames.success;

  /// Stream of scenario change events.
  Stream<ScenarioChangeEvent> get onScenarioChange => _streamController.stream;

  /// Active global scenario.
  String get activeGlobalScenario => _activeGlobalScenario;

  /// Map of route-specific active scenarios.
  Map<String, String> get routeActiveScenarios =>
      Map.unmodifiable(_routeActiveScenarios);

  /// Map of all registered scenario definitions.
  Map<String, RouteScenarioDefinition> get definitions =>
      Map.unmodifiable(_definitions);

  /// Register scenario definitions for a route or group name.
  void register(
    String routeOrGroupName,
    Map<String, MockResponse> responses, {
    String defaultScenario = ScenarioNames.success,
  }) {
    _definitions[routeOrGroupName] = RouteScenarioDefinition(
      name: routeOrGroupName,
      responses: responses,
      defaultScenario: defaultScenario,
    );
  }

  /// Activate a global scenario.
  void activateGlobal(String scenario) {
    final prev = _activeGlobalScenario;
    _activeGlobalScenario = scenario;
    if (!_streamController.isClosed) {
      _streamController.add(
        ScenarioChangeEvent(
          previousScenario: prev,
          newScenario: scenario,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Activate scenario for a specific route or group.
  void activateForRoute(String routeOrGroupName, String scenario) {
    final prev = _routeActiveScenarios[routeOrGroupName];
    _routeActiveScenarios[routeOrGroupName] = scenario;
    if (!_streamController.isClosed) {
      _streamController.add(
        ScenarioChangeEvent(
          previousScenario: prev,
          newScenario: scenario,
          routeName: routeOrGroupName,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Clears route-specific scenario override.
  void resetRouteScenario(String routeOrGroupName) {
    final prev = _routeActiveScenarios.remove(routeOrGroupName);
    if (prev != null) {
      _streamController.add(
        ScenarioChangeEvent(
          previousScenario: prev,
          newScenario: null,
          routeName: routeOrGroupName,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Resets all scenario overrides back to default.
  void resetAll() {
    _routeActiveScenarios.clear();
    activateGlobal(ScenarioNames.success);
  }

  /// Resolves the response for a given route definition using the active scenario hierarchy.
  MockResponse? resolveResponse(String routeOrGroupName) {
    final def = _definitions[routeOrGroupName];
    if (def == null) return null;

    // Route-specific scenario has highest priority
    final routeScenario = _routeActiveScenarios[routeOrGroupName];
    if (routeScenario != null) {
      final res = def.getResponse(routeScenario);
      if (res != null) return res;
    }

    // Global scenario
    final globalRes = def.getResponse(_activeGlobalScenario);
    if (globalRes != null) return globalRes;

    // Default fallback
    return def.getResponse(def.defaultScenario);
  }

  /// Disposes scenario manager stream resources.
  void dispose() {
    _streamController.close();
  }
}
