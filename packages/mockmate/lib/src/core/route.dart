import 'dart:async';
import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/request_response.dart';

typedef MockResponseHandler = FutureOr<MockResponse> Function(
    MockRequest request);

/// Representation of a registered mock route.
class MockRoute {
  MockRoute({
    required this.method,
    required this.pathPattern,
    required this.handler,
    this.name,
    this.priority = 0,
    this.requiredHeaders = const {},
    this.requiredQueryParams = const {},
    this.bodyMatcher,
  });

  final HttpMethod method;
  final String pathPattern;
  final MockResponseHandler handler;
  final String? name;
  final int priority;
  final Map<String, String> requiredHeaders;
  final Map<String, String> requiredQueryParams;
  final bool Function(Object? body)? bodyMatcher;

  Map<String, dynamic> toJson() {
    return {
      'method': method.toVerb(),
      'pathPattern': pathPattern,
      'name': name,
      'priority': priority,
      'requiredHeaders': requiredHeaders,
      'requiredQueryParams': requiredQueryParams,
    };
  }
}

/// Result of matching a request against registered routes.
class RouteMatchResult {
  const RouteMatchResult({
    required this.route,
    required this.pathParameters,
  });

  final MockRoute route;
  final Map<String, String> pathParameters;
}
