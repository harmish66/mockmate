import 'dart:async';
import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/recorder/recorded_request.dart';

/// Replay execution result comparing previous and replayed transaction.
class ReplayResult {
  const ReplayResult({
    required this.originalTransaction,
    required this.replayedRequest,
    required this.replayedResponse,
    required this.duration,
    this.errorMessage,
  });

  final RecordedTransaction originalTransaction;
  final MockRequest replayedRequest;
  final MockResponse? replayedResponse;
  final Duration duration;
  final String? errorMessage;

  bool get isMatch =>
      replayedResponse != null &&
      replayedResponse!.statusCode == originalTransaction.statusCode;
}

/// Dispatches recorded requests through a mock request handler.
class ReplayEngine {
  const ReplayEngine();

  /// Replays a previously recorded transaction through [handler].
  /// Optionally allows overriding [modifiedRequest].
  Future<ReplayResult> replay({
    required RecordedTransaction transaction,
    required Future<MockResponse> Function(MockRequest request) handler,
    MockRequest? modifiedRequest,
  }) async {
    final reqToExecute = modifiedRequest ?? transaction.request;
    final stopwatch = Stopwatch()..start();

    try {
      final response = await handler(reqToExecute);
      stopwatch.stop();
      return ReplayResult(
        originalTransaction: transaction,
        replayedRequest: reqToExecute,
        replayedResponse: response,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return ReplayResult(
        originalTransaction: transaction,
        replayedRequest: reqToExecute,
        replayedResponse: null,
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
      );
    }
  }
}
