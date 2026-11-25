import 'dart:async';
import 'dart:convert';
import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/recorder/recorded_request.dart';
import 'package:mockmate/src/recorder/redaction_rules.dart';

/// Recorder that captures requests, responses, timing, and errors with redaction.
class RequestRecorder {
  RequestRecorder({
    RedactionRules? redactionRules,
    this.maxHistory = 200,
  }) : redactionRules = redactionRules ?? RedactionRules() {
    _streamController = StreamController<RecordedTransaction>.broadcast();
  }

  final RedactionRules redactionRules;
  final int maxHistory;
  final List<RecordedTransaction> _history = [];
  late final StreamController<RecordedTransaction> _streamController;

  bool _isRecording = true;
  bool _isPaused = false;

  /// Stream of recorded transactions as they happen.
  Stream<RecordedTransaction> get onTransaction => _streamController.stream;

  /// Unmodifiable view of recorded transactions.
  List<RecordedTransaction> get history => List.unmodifiable(_history);

  /// Whether recorder is actively logging.
  bool get isRecording => _isRecording && !_isPaused;

  /// Total count of recorded items.
  int get count => _history.length;

  /// Starts or resumes recording.
  void start() {
    _isRecording = true;
    _isPaused = false;
  }

  /// Stops recording.
  void stop() {
    _isRecording = false;
    _isPaused = false;
  }

  /// Pauses recording.
  void pause() {
    _isPaused = true;
  }

  /// Clears recorded history.
  void clear() {
    _history.clear();
  }

  /// Records a completed HTTP transaction.
  void record({
    required MockRequest request,
    MockResponse? response,
    required Duration duration,
    String? matchedRoute,
    String? activeScenario,
    String? errorDetails,
  }) {
    if (!isRecording) return;

    // Apply sensitive data redactions
    final cleanReq = MockRequest(
      id: request.id,
      method: request.method,
      uri: request.uri,
      headers: redactionRules.redactHeaders(request.headers),
      body: redactionRules.redactBody(request.body),
      timestamp: request.timestamp,
      pathParameters: request.pathParameters,
    );

    MockResponse? cleanRes;
    if (response != null) {
      cleanRes = MockResponse(
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: redactionRules.redactHeaders(response.headers),
        body: redactionRules.redactBody(response.body),
        delay: response.delay,
      );
    }

    final tx = RecordedTransaction(
      id: cleanReq.id,
      request: cleanReq,
      response: cleanRes,
      duration: duration,
      matchedRoute: matchedRoute,
      activeScenario: activeScenario,
      errorDetails: errorDetails,
      recordedAt: DateTime.now(),
    );

    _history.insert(0, tx);
    if (_history.length > maxHistory) {
      _history.removeLast();
    }

    if (!_streamController.isClosed) {
      _streamController.add(tx);
    }
  }

  /// Filters history by search query, method, and status code.
  List<RecordedTransaction> filter({
    String? query,
    HttpMethod? method,
    int? statusCode,
    bool? onlyErrors,
  }) {
    return _history.where((tx) {
      if (method != null && tx.request.method != method) return false;
      if (statusCode != null && tx.statusCode != statusCode) return false;
      if (onlyErrors == true && !tx.isError) return false;

      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final pathMatch = tx.request.path.toLowerCase().contains(q);
        final urlMatch = tx.request.uri.toString().toLowerCase().contains(q);
        final methodMatch =
            tx.request.method.toVerb().toLowerCase().contains(q);
        if (!pathMatch && !urlMatch && !methodMatch) return false;
      }

      return true;
    }).toList();
  }

  /// Exports history to JSON string.
  String exportJson() {
    final list = _history.map((e) => e.toJson()).toList();
    return jsonEncode(list);
  }

  /// Imports history from JSON string.
  void importJson(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          _history.add(RecordedTransaction.fromJson(item));
        }
      }
    }
  }

  /// Cleans up stream controller.
  void dispose() {
    _streamController.close();
  }
}
