/// Exception thrown when simulated network is offline.
class MockOfflineException implements Exception {
  const MockOfflineException([this.message = 'Network is offline']);
  final String message;

  @override
  String toString() => 'MockOfflineException: $message';
}

/// Exception thrown when a simulated request or response times out.
class MockTimeoutException implements Exception {
  const MockTimeoutException([this.message = 'Simulated request timeout']);
  final String message;

  @override
  String toString() => 'MockTimeoutException: $message';
}

/// Generic simulated network exception.
class MockNetworkException implements Exception {
  const MockNetworkException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'MockNetworkException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}
