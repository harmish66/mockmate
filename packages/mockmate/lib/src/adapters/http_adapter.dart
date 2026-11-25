import 'package:http/http.dart' as http;
import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/mockmate_engine.dart';
import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/network/network_exceptions.dart';

/// package:http client that intercepts HTTP calls and routes them through MockMate.
class MockMateHttpClient extends http.BaseClient {
  MockMateHttpClient({
    required this.mockMate,
    http.Client? innerClient,
    this.passthrough = false,
  }) : _innerClient = innerClient ?? http.Client();

  final MockMate mockMate;
  final http.Client _innerClient;
  final bool passthrough;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final method = HttpMethod.fromString(request.method);
    final uri = request.url;

    Object? body;
    if (request is http.Request) {
      body = request.body;
    }

    final mockReq = MockRequest(
      method: method,
      uri: uri,
      headers: request.headers,
      body: body,
    );

    if (passthrough && mockMate.router.findRoute(mockReq) == null) {
      return _innerClient.send(request);
    }

    try {
      final mockRes = await mockMate.handleRequest(mockReq);
      final bytes = mockRes.bodyAsBytes ?? <int>[];

      return http.StreamedResponse(
        Stream.value(bytes),
        mockRes.statusCode,
        headers: mockRes.headers,
        reasonPhrase: mockRes.statusMessage,
      );
    } on MockOfflineException catch (e) {
      throw http.ClientException(e.message, uri);
    } on MockTimeoutException catch (e) {
      throw http.ClientException(e.message, uri);
    } on MockNetworkException catch (e) {
      throw http.ClientException(e.message, uri);
    }
  }

  @override
  void close() {
    _innerClient.close();
    super.close();
  }
}
