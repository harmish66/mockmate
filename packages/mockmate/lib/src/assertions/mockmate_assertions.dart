import 'package:matcher/matcher.dart';
import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/mockmate_engine.dart';
import 'package:mockmate/src/recorder/recorded_request.dart';

/// Matcher to verify that MockMate recorded a request matching given criteria.
Matcher hasRequested({
  HttpMethod? method,
  String? path,
  int? count,
  int? statusCode,
}) {
  return _HasRequestedMatcher(
    method: method,
    path: path,
    expectedCount: count,
    statusCode: statusCode,
  );
}

class _HasRequestedMatcher extends Matcher {
  const _HasRequestedMatcher({
    this.method,
    this.path,
    this.expectedCount,
    this.statusCode,
  });

  final HttpMethod? method;
  final String? path;
  final int? expectedCount;
  final int? statusCode;

  @override
  bool matches(dynamic item, Map matchState) {
    List<RecordedTransaction> history;
    if (item is MockMate) {
      history = item.requestHistory;
    } else if (item is List<RecordedTransaction>) {
      history = item;
    } else {
      return false;
    }

    final matched = history.where((tx) {
      if (method != null && tx.request.method != method) return false;
      if (path != null && tx.request.path != path) return false;
      if (statusCode != null && tx.statusCode != statusCode) return false;
      return true;
    }).toList();

    matchState['matchedCount'] = matched.length;

    if (expectedCount != null) {
      return matched.length == expectedCount;
    }

    return matched.isNotEmpty;
  }

  @override
  Description describe(Description description) {
    description.add('a recorded request with ');
    if (method != null) description.add('method: ${method!.toVerb()} ');
    if (path != null) description.add('path: "$path" ');
    if (statusCode != null) description.add('status: $statusCode ');
    if (expectedCount != null) description.add('count: $expectedCount');
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final count = matchState['matchedCount'] ?? 0;
    return mismatchDescription.add('found $count matching requests');
  }
}
