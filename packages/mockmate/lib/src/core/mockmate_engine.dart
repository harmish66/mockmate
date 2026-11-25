import 'dart:async';
import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/core/route.dart';
import 'package:mockmate/src/core/router.dart';
import 'package:mockmate/src/database/mock_database.dart';
import 'package:mockmate/src/database/mock_resource.dart';
import 'package:mockmate/src/fixtures/fixture_manager.dart';
import 'package:mockmate/src/network/network_profile.dart';
import 'package:mockmate/src/network/network_simulator.dart';
import 'package:mockmate/src/openapi/openapi_importer.dart';
import 'package:mockmate/src/openapi/openapi_models.dart';
import 'package:mockmate/src/recorder/recorded_request.dart';
import 'package:mockmate/src/recorder/replay_engine.dart';
import 'package:mockmate/src/recorder/request_recorder.dart';
import 'package:mockmate/src/scenarios/scenario.dart';
import 'package:mockmate/src/scenarios/scenario_manager.dart';

/// The central MockMate mocking engine.
class MockMate {
  MockMate({
    NetworkProfile? defaultNetworkProfile,
    DelayProvider? delayProvider,
    int? randomSeed,
    int maxHistory = 200,
  }) {
    router = Router();
    scenarioManager = ScenarioManager();
    network = NetworkSimulator(
      profile: defaultNetworkProfile,
      delayProvider: delayProvider,
      randomSeed: randomSeed,
    );
    database = MockDatabase(router: router);
    recorder = RequestRecorder(maxHistory: maxHistory);
    replayEngine = const ReplayEngine();
    fixtures = FixtureManager();
    openApi = const OpenApiImporter();
  }

  late final Router router;
  late final ScenarioManager scenarioManager;
  late final NetworkSimulator network;
  late final MockDatabase database;
  late final RequestRecorder recorder;
  late final ReplayEngine replayEngine;
  late final FixtureManager fixtures;
  late final OpenApiImporter openApi;

  /// Convenience access to recorded transactions history.
  List<RecordedTransaction> get requestHistory => recorder.history;

  /// Registers a GET route.
  void get(
    String path,
    MockResponseHandler handler, {
    String? name,
    int priority = 0,
    Map<String, String> requiredHeaders = const {},
    Map<String, String> requiredQueryParams = const {},
    bool Function(Object? body)? bodyMatcher,
  }) {
    router.register(
      MockRoute(
        method: HttpMethod.get,
        pathPattern: path,
        handler: handler,
        name: name,
        priority: priority,
        requiredHeaders: requiredHeaders,
        requiredQueryParams: requiredQueryParams,
        bodyMatcher: bodyMatcher,
      ),
    );
  }

  /// Registers a POST route.
  void post(
    String path,
    MockResponseHandler handler, {
    String? name,
    int priority = 0,
    Map<String, String> requiredHeaders = const {},
    Map<String, String> requiredQueryParams = const {},
    bool Function(Object? body)? bodyMatcher,
  }) {
    router.register(
      MockRoute(
        method: HttpMethod.post,
        pathPattern: path,
        handler: handler,
        name: name,
        priority: priority,
        requiredHeaders: requiredHeaders,
        requiredQueryParams: requiredQueryParams,
        bodyMatcher: bodyMatcher,
      ),
    );
  }

  /// Registers a PUT route.
  void put(
    String path,
    MockResponseHandler handler, {
    String? name,
    int priority = 0,
    Map<String, String> requiredHeaders = const {},
    Map<String, String> requiredQueryParams = const {},
    bool Function(Object? body)? bodyMatcher,
  }) {
    router.register(
      MockRoute(
        method: HttpMethod.put,
        pathPattern: path,
        handler: handler,
        name: name,
        priority: priority,
        requiredHeaders: requiredHeaders,
        requiredQueryParams: requiredQueryParams,
        bodyMatcher: bodyMatcher,
      ),
    );
  }

  /// Registers a PATCH route.
  void patch(
    String path,
    MockResponseHandler handler, {
    String? name,
    int priority = 0,
    Map<String, String> requiredHeaders = const {},
    Map<String, String> requiredQueryParams = const {},
    bool Function(Object? body)? bodyMatcher,
  }) {
    router.register(
      MockRoute(
        method: HttpMethod.patch,
        pathPattern: path,
        handler: handler,
        name: name,
        priority: priority,
        requiredHeaders: requiredHeaders,
        requiredQueryParams: requiredQueryParams,
        bodyMatcher: bodyMatcher,
      ),
    );
  }

  /// Registers a DELETE route.
  void delete(
    String path,
    MockResponseHandler handler, {
    String? name,
    int priority = 0,
    Map<String, String> requiredHeaders = const {},
    Map<String, String> requiredQueryParams = const {},
    bool Function(Object? body)? bodyMatcher,
  }) {
    router.register(
      MockRoute(
        method: HttpMethod.delete,
        pathPattern: path,
        handler: handler,
        name: name,
        priority: priority,
        requiredHeaders: requiredHeaders,
        requiredQueryParams: requiredQueryParams,
        bodyMatcher: bodyMatcher,
      ),
    );
  }

  /// Registers a HEAD route.
  void head(
    String path,
    MockResponseHandler handler, {
    String? name,
    int priority = 0,
  }) {
    router.register(
      MockRoute(
        method: HttpMethod.head,
        pathPattern: path,
        handler: handler,
        name: name,
        priority: priority,
      ),
    );
  }

  /// Registers an OPTIONS route.
  void options(
    String path,
    MockResponseHandler handler, {
    String? name,
    int priority = 0,
  }) {
    router.register(
      MockRoute(
        method: HttpMethod.options,
        pathPattern: path,
        handler: handler,
        name: name,
        priority: priority,
      ),
    );
  }

  /// Defines scenario responses for a route or group.
  void scenario(
    String routeOrGroupName,
    Map<String, MockResponse> responses, {
    String defaultScenario = ScenarioNames.success,
  }) {
    scenarioManager.register(
      routeOrGroupName,
      responses,
      defaultScenario: defaultScenario,
    );
  }

  /// Activates a global scenario (e.g. 'success', 'empty', 'serverError', 'unauthorized').
  void activateScenario(String scenario) {
    scenarioManager.activateGlobal(scenario);
  }

  /// Activates a route-specific scenario override.
  void activateRouteScenario(String routeOrGroupName, String scenario) {
    scenarioManager.activateForRoute(routeOrGroupName, scenario);
  }

  /// Registers a stateful CRUD REST resource with auto-generated GET, POST, PUT, PATCH, DELETE routes.
  MockResource resource(
    String basePath, {
    List<Map<String, dynamic>>? initialData,
    String idField = 'id',
    bool autoIncrement = true,
  }) {
    return database.registerResource(
      basePath,
      initialData: initialData,
      idField: idField,
      autoIncrement: autoIncrement,
    );
  }

  /// Imports an OpenAPI 3.x specification and registers mock routes.
  OpenApiImportReport importOpenApi(dynamic openApiSource) {
    final report = openApi.parse(openApiSource);
    openApi.registerToRouter(router, report);
    return report;
  }

  /// Executes request through MockMate handling pipeline:
  /// 1. Network simulation (latency, failure rate, offline check)
  /// 2. Scenario resolution
  /// 3. Route matching
  /// 4. Handler execution
  /// 5. Recorder transaction logging
  Future<MockResponse> handleRequest(MockRequest request) async {
    final stopwatch = Stopwatch()..start();
    String? matchedRoutePattern;
    String? activeScenarioName = scenarioManager.activeGlobalScenario;

    try {
      // 1. Simulate network conditions
      await network.simulate();

      // 2. Check for scenario override matching this route
      final match = router.findRoute(request);
      if (match != null) {
        matchedRoutePattern = match.route.pathPattern;
        final routeName = match.route.name ?? match.route.pathPattern;
        var scenarioOverride = scenarioManager.resolveResponse(routeName);
        if (scenarioOverride == null && match.route.name != null) {
          scenarioOverride =
              scenarioManager.resolveResponse(match.route.pathPattern);
        }
        if (scenarioOverride == null) {
          final cleanPattern = match.route.pathPattern.replaceFirst('/', '');
          scenarioOverride = scenarioManager.resolveResponse(cleanPattern);
        }
        if (scenarioOverride == null && match.route.pathPattern.contains('/')) {
          final lastSeg = match.route.pathPattern
              .split('/')
              .where((s) => s.isNotEmpty)
              .lastOrNull;
          if (lastSeg != null) {
            scenarioOverride = scenarioManager.resolveResponse(lastSeg);
          }
        }
        if (scenarioOverride != null) {
          stopwatch.stop();
          recorder.record(
            request: request,
            response: scenarioOverride,
            duration: stopwatch.elapsed,
            matchedRoute: matchedRoutePattern,
            activeScenario: scenarioManager.routeActiveScenarios[routeName] ??
                activeScenarioName,
          );
          if (scenarioOverride.delay != null) {
            await network.delayProvider.delay(scenarioOverride.delay!);
          }
          return scenarioOverride;
        }
      }

      // 3. Normal route handling
      final response = await router.handle(request);
      stopwatch.stop();

      recorder.record(
        request: request,
        response: response,
        duration: stopwatch.elapsed,
        matchedRoute: matchedRoutePattern,
        activeScenario: activeScenarioName,
      );

      if (response.delay != null) {
        await network.delayProvider.delay(response.delay!);
      }

      return response;
    } catch (e) {
      stopwatch.stop();
      recorder.record(
        request: request,
        response: null,
        duration: stopwatch.elapsed,
        matchedRoute: matchedRoutePattern,
        activeScenario: activeScenarioName,
        errorDetails: e.toString(),
      );
      rethrow;
    }
  }

  /// Resets state of all database resources, recorder history, and scenarios.
  void reset() {
    database.resetAll();
    recorder.clear();
    scenarioManager.resetAll();
    router.clear();
  }

  /// Disposes internal streams and resources.
  void dispose() {
    scenarioManager.dispose();
    recorder.dispose();
  }
}
