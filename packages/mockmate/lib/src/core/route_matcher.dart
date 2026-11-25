import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/core/route.dart';

/// Matches incoming requests against route path patterns.
class RouteMatcher {
  const RouteMatcher();

  /// Attempts to match [request] against [route].
  /// Returns [RouteMatchResult] if matched, otherwise null.
  RouteMatchResult? match(MockRequest request, MockRoute route) {
    // 1. Method check
    if (request.method != route.method) {
      return null;
    }

    // 2. Query param requirements check
    if (route.requiredQueryParams.isNotEmpty) {
      for (final entry in route.requiredQueryParams.entries) {
        final val = request.queryParameters[entry.key];
        if (val == null || val != entry.value) {
          return null;
        }
      }
    }

    // 3. Header requirements check
    if (route.requiredHeaders.isNotEmpty) {
      for (final entry in route.requiredHeaders.entries) {
        final reqHeaderVal =
            _findHeaderCaseInsensitive(request.headers, entry.key);
        if (reqHeaderVal == null || reqHeaderVal != entry.value) {
          return null;
        }
      }
    }

    // 4. Body matcher check
    if (route.bodyMatcher != null && !route.bodyMatcher!(request.body)) {
      return null;
    }

    // 5. Path pattern check
    final pathParams = _matchPath(route.pathPattern, request.path);
    if (pathParams == null) {
      return null;
    }

    return RouteMatchResult(route: route, pathParameters: pathParams);
  }

  static String? _findHeaderCaseInsensitive(
      Map<String, String> headers, String key) {
    final lowerKey = key.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        return entry.value;
      }
    }
    return null;
  }

  /// Matches pattern segments with requested path segments.
  /// Supports:
  /// - Exact match: `/api/products`
  /// - Named params: `/api/users/:id`
  /// - Wildcards: `/static/*`
  static Map<String, String>? _matchPath(String pattern, String path) {
    final patternClean = _normalizePath(pattern);
    final pathClean = _normalizePath(path);

    if (patternClean == pathClean) {
      return const <String, String>{};
    }

    final pSegs = patternClean.split('/').where((s) => s.isNotEmpty).toList();
    final aSegs = pathClean.split('/').where((s) => s.isNotEmpty).toList();

    // Check wildcard suffix
    final hasWildcard = pSegs.isNotEmpty && pSegs.last == '*';
    if (!hasWildcard && pSegs.length != aSegs.length) {
      return null;
    }
    if (hasWildcard && aSegs.length < pSegs.length - 1) {
      return null;
    }

    final params = <String, String>{};
    final limit = hasWildcard ? pSegs.length - 1 : pSegs.length;

    for (var i = 0; i < limit; i++) {
      final p = pSegs[i];
      final a = aSegs[i];

      if (p.startsWith(':')) {
        final paramName = p.substring(1);
        params[paramName] = Uri.decodeComponent(a);
      } else if (p != a) {
        return null;
      }
    }

    if (hasWildcard) {
      final remaining = aSegs.skip(limit).map(Uri.decodeComponent).join('/');
      params['wildcard'] = remaining;
    }

    return params;
  }

  static String _normalizePath(String path) {
    var p = path.trim();
    if (!p.startsWith('/')) {
      p = '/$p';
    }
    if (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }
}
