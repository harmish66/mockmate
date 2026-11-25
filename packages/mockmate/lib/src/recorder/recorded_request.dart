import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/request_response.dart';

/// Representation of an HTTP transaction recorded by MockMate.
class RecordedTransaction {
  RecordedTransaction({
    required this.id,
    required this.request,
    this.response,
    required this.duration,
    this.matchedRoute,
    this.activeScenario,
    this.errorDetails,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  final String id;
  final MockRequest request;
  final MockResponse? response;
  final Duration duration;
  final String? matchedRoute;
  final String? activeScenario;
  final String? errorDetails;
  final DateTime recordedAt;

  bool get isSuccess => response?.isSuccess ?? false;
  bool get isError => errorDetails != null || (response?.isError ?? true);
  int get statusCode =>
      response?.statusCode ?? (errorDetails != null ? 0 : 200);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request': request.toJson(),
      'response': response?.toJson(),
      'durationMs': duration.inMilliseconds,
      'matchedRoute': matchedRoute,
      'activeScenario': activeScenario,
      'errorDetails': errorDetails,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory RecordedTransaction.fromJson(Map<String, dynamic> json) {
    final reqMap = json['request'] as Map<String, dynamic>;
    final req = MockRequest(
      id: reqMap['id'] as String?,
      method: HttpMethod.fromString(reqMap['method'] as String),
      uri: Uri.parse(reqMap['url'] as String),
      headers: Map<String, String>.from(reqMap['headers'] as Map? ?? {}),
      body: reqMap['body'],
      timestamp: DateTime.parse(reqMap['timestamp'] as String),
      pathParameters:
          Map<String, String>.from(reqMap['pathParameters'] as Map? ?? {}),
    );

    MockResponse? res;
    if (json['response'] != null) {
      final resMap = json['response'] as Map<String, dynamic>;
      res = MockResponse(
        statusCode: resMap['statusCode'] as int? ?? 200,
        statusMessage: resMap['statusMessage'] as String?,
        headers: Map<String, String>.from(resMap['headers'] as Map? ?? {}),
        body: resMap['body'],
        delay: resMap['delayMs'] != null
            ? Duration(milliseconds: resMap['delayMs'] as int)
            : null,
      );
    }

    return RecordedTransaction(
      id: json['id'] as String,
      request: req,
      response: res,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      matchedRoute: json['matchedRoute'] as String?,
      activeScenario: json['activeScenario'] as String?,
      errorDetails: json['errorDetails'] as String?,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }
}
