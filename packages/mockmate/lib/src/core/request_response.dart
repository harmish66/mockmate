import 'dart:convert';
import 'dart:typed_data';
import 'package:mockmate/src/core/http_method.dart';

/// Strongly typed request representation for MockMate.
class MockRequest {
  MockRequest({
    required this.method,
    required this.uri,
    Map<String, String>? headers,
    this.body,
    DateTime? timestamp,
    this.pathParameters = const {},
    String? id,
  })  : headers = Map.unmodifiable(headers ?? <String, String>{}),
        timestamp = timestamp ?? DateTime.now(),
        id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  final HttpMethod method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body;
  final DateTime timestamp;
  final Map<String, String> pathParameters;

  String get path => uri.path;
  Map<String, String> get queryParameters => uri.queryParameters;

  /// Returns the body converted to a UTF-8 string, or null if body is null.
  String? get bodyAsString {
    if (body == null) return null;
    if (body is String) return body as String;
    if (body is List<int>) return utf8.decode(body as List<int>);
    return jsonEncode(body);
  }

  /// Returns the body converted to bytes.
  Uint8List? get bodyAsBytes {
    if (body == null) return null;
    if (body is Uint8List) return body as Uint8List;
    if (body is List<int>) return Uint8List.fromList(body as List<int>);
    if (body is String) return Uint8List.fromList(utf8.encode(body as String));
    return Uint8List.fromList(utf8.encode(jsonEncode(body)));
  }

  /// Parses body as JSON map or list.
  dynamic get bodyAsJson {
    final str = bodyAsString;
    if (str == null || str.trim().isEmpty) return null;
    return jsonDecode(str);
  }

  /// Returns a copy of this request with updated path parameters.
  MockRequest copyWith({
    HttpMethod? method,
    Uri? uri,
    Map<String, String>? headers,
    Object? body,
    DateTime? timestamp,
    Map<String, String>? pathParameters,
    String? id,
  }) {
    return MockRequest(
      id: id ?? this.id,
      method: method ?? this.method,
      uri: uri ?? this.uri,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      pathParameters: pathParameters ?? this.pathParameters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method.toVerb(),
      'url': uri.toString(),
      'path': path,
      'headers': headers,
      'queryParameters': queryParameters,
      'pathParameters': pathParameters,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Strongly typed response representation for MockMate.
class MockResponse {
  MockResponse({
    this.statusCode = 200,
    Map<String, String>? headers,
    this.body,
    this.delay,
    this.statusMessage,
  }) : headers = Map<String, String>.from(headers ?? const <String, String>{});

  /// Factory for JSON responses.
  factory MockResponse.json({
    int statusCode = 200,
    Object? body,
    Map<String, String>? headers,
    Duration? delay,
    String? statusMessage,
  }) {
    final effectiveHeaders = <String, String>{
      'content-type': 'application/json; charset=utf-8',
      ...?headers,
    };
    return MockResponse(
      statusCode: statusCode,
      headers: effectiveHeaders,
      body: body is String ? body : (body == null ? 'null' : jsonEncode(body)),
      delay: delay,
      statusMessage: statusMessage ?? _defaultStatusMessage(statusCode),
    );
  }

  /// Factory for plain text responses.
  factory MockResponse.text(
    String text, {
    int statusCode = 200,
    Map<String, String>? headers,
    Duration? delay,
    String? statusMessage,
  }) {
    final effectiveHeaders = <String, String>{
      'content-type': 'text/plain; charset=utf-8',
      ...?headers,
    };
    return MockResponse(
      statusCode: statusCode,
      headers: effectiveHeaders,
      body: text,
      delay: delay,
      statusMessage: statusMessage ?? _defaultStatusMessage(statusCode),
    );
  }

  /// Factory for empty responses.
  factory MockResponse.empty({
    int statusCode = 204,
    Map<String, String>? headers,
    Duration? delay,
    String? statusMessage,
  }) {
    return MockResponse(
      statusCode: statusCode,
      headers: headers,
      body: null,
      delay: delay,
      statusMessage: statusMessage ?? _defaultStatusMessage(statusCode),
    );
  }

  /// Factory for binary responses.
  factory MockResponse.bytes(
    List<int> bytes, {
    int statusCode = 200,
    String contentType = 'application/octet-stream',
    Map<String, String>? headers,
    Duration? delay,
    String? statusMessage,
  }) {
    final effectiveHeaders = <String, String>{
      'content-type': contentType,
      ...?headers,
    };
    return MockResponse(
      statusCode: statusCode,
      headers: effectiveHeaders,
      body: Uint8List.fromList(bytes),
      delay: delay,
      statusMessage: statusMessage ?? _defaultStatusMessage(statusCode),
    );
  }

  /// Factory for error responses.
  factory MockResponse.error({
    int statusCode = 500,
    String message = 'Internal Server Error',
    Map<String, String>? headers,
    Duration? delay,
  }) {
    return MockResponse.json(
      statusCode: statusCode,
      body: {'error': message, 'statusCode': statusCode},
      headers: headers,
      delay: delay,
      statusMessage: message,
    );
  }

  final int statusCode;
  final Map<String, String> headers;
  final Object? body;
  final Duration? delay;
  final String? statusMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isError => statusCode >= 400;

  /// Returns body as string.
  String? get bodyAsString {
    if (body == null) return null;
    if (body is String) return body as String;
    if (body is List<int>) return utf8.decode(body as List<int>);
    return jsonEncode(body);
  }

  /// Returns body as byte list.
  Uint8List? get bodyAsBytes {
    if (body == null) return null;
    if (body is Uint8List) return body as Uint8List;
    if (body is List<int>) return Uint8List.fromList(body as List<int>);
    if (body is String) return Uint8List.fromList(utf8.encode(body as String));
    return Uint8List.fromList(utf8.encode(jsonEncode(body)));
  }

  /// Parses body as JSON.
  dynamic get bodyAsJson {
    final str = bodyAsString;
    if (str == null || str.trim().isEmpty) return null;
    return jsonDecode(str);
  }

  static String _defaultStatusMessage(int code) {
    switch (code) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 204:
        return 'No Content';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 408:
        return 'Request Timeout';
      case 422:
        return 'Unprocessable Entity';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      default:
        return 'Status $code';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'headers': headers,
      'body': bodyAsString,
      'delayMs': delay?.inMilliseconds,
    };
  }
}
