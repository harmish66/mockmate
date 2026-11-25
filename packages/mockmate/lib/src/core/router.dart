import 'dart:async';
import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/core/route.dart';
import 'package:mockmate/src/core/route_matcher.dart';

/// Exception thrown when a request cannot be matched to any route.
class RouteNotFoundException implements Exception {
  RouteNotFoundException(this.request);

  final MockRequest request;

  @override
  String toString() =>
      'RouteNotFoundException: No mock route found for ${request.method.toVerb()} ${request.path}';
}

/// Manages registration and resolution of mock routes.
class Router {
  Router({RouteMatcher matcher = const RouteMatcher()}) : _matcher = matcher;

  final RouteMatcher _matcher;
  final List<MockRoute> _routes = [];
  MockResponseHandler? _fallbackHandler;

  /// All currently registered routes.
  List<MockRoute> get routes => List.unmodifiable(_routes);

  /// Registers a fallback handler when no route matches.
  void setFallback(MockResponseHandler? handler) {
    _fallbackHandler = handler;
  }

  /// Adds a new route. Routes with higher priority are matched first.
  void register(MockRoute route) {
    _routes.add(route);
    // Sort descending by priority so higher priority is tested first
    _routes.sort((a, b) => b.priority.compareTo(a.priority));
  }

  /// Removes routes matching method and pathPattern.
  void unregister(HttpMethod method, String pathPattern) {
    _routes
        .removeWhere((r) => r.method == method && r.pathPattern == pathPattern);
  }

  /// Clears all registered routes.
  void clear() {
    _routes.clear();
    _fallbackHandler = null;
  }

  /// Finds the first matching route for [request].
  RouteMatchResult? findRoute(MockRequest request) {
    for (final route in _routes) {
      final match = _matcher.match(request, route);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  /// Handles incoming [request].
  /// Returns a [MockResponse].
  Future<MockResponse> handle(MockRequest request) async {
    final match = findRoute(request);
    if (match != null) {
      final reqWithParams =
          request.copyWith(pathParameters: match.pathParameters);
      final response = await match.route.handler(reqWithParams);
      return response;
    }

    if (_fallbackHandler != null) {
      final response = await _fallbackHandler!(request);
      return response;
    }

    return MockResponse.error(
      statusCode: 404,
      message: 'Route not found: ${request.method.toVerb()} ${request.path}',
    );
  }
}
