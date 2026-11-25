import 'package:mockmate/src/core/request_response.dart';

/// Predefined standard scenario names.
class ScenarioNames {
  static const String success = 'success';
  static const String loading = 'loading';
  static const String empty = 'empty';
  static const String unauthorized = 'unauthorized';
  static const String forbidden = 'forbidden';
  static const String notFound = 'notFound';
  static const String serverError = 'serverError';
  static const String timeout = 'timeout';
  static const String offline = 'offline';
  static const String slowNetwork = 'slowNetwork';
  static const String custom = 'custom';

  static const List<String> allStandard = [
    success,
    loading,
    empty,
    unauthorized,
    forbidden,
    notFound,
    serverError,
    timeout,
    offline,
    slowNetwork,
    custom,
  ];
}

/// A scenario definition containing a mapping of scenario names to responses or handlers.
class RouteScenarioDefinition {
  RouteScenarioDefinition({
    required this.name,
    required Map<String, MockResponse> responses,
    this.defaultScenario = ScenarioNames.success,
  }) : responses = Map.unmodifiable(responses);

  final String name;
  final Map<String, MockResponse> responses;
  final String defaultScenario;

  List<String> get availableScenarios => responses.keys.toList();

  MockResponse? getResponse(String scenario) {
    return responses[scenario] ?? responses[defaultScenario];
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'defaultScenario': defaultScenario,
      'availableScenarios': availableScenarios,
    };
  }
}
