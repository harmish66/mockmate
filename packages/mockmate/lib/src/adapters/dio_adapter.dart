import 'package:dio/dio.dart';
import 'package:mockmate/src/core/http_method.dart';
import 'package:mockmate/src/core/mockmate_engine.dart';
import 'package:mockmate/src/core/request_response.dart';
import 'package:mockmate/src/network/network_exceptions.dart';

/// Dio Interceptor that routes outgoing requests through MockMate.
class MockMateDioAdapter extends Interceptor {
  MockMateDioAdapter(this.mockMate, {this.passthrough = false});

  final MockMate mockMate;
  final bool passthrough;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final method = HttpMethod.fromString(options.method);
    final uri = options.uri;

    final headers = <String, String>{};
    options.headers.forEach((k, v) {
      if (v != null) headers[k] = v.toString();
    });

    final mockReq = MockRequest(
      method: method,
      uri: uri,
      headers: headers,
      body: options.data,
    );

    // If passthrough is enabled and no route matches, pass through to real network
    if (passthrough && mockMate.router.findRoute(mockReq) == null) {
      return handler.next(options);
    }

    try {
      final mockRes = await mockMate.handleRequest(mockReq);

      if (mockRes.isError) {
        return handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: mockRes.statusCode,
              statusMessage: mockRes.statusMessage,
              data: mockRes.bodyAsJson ?? mockRes.bodyAsString,
              headers: Headers.fromMap(
                mockRes.headers.map((k, v) => MapEntry(k, [v])),
              ),
            ),
            type: DioExceptionType.badResponse,
            message: mockRes.statusMessage,
          ),
        );
      }

      final responseData = mockRes.bodyAsJson ?? mockRes.bodyAsString;

      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: mockRes.statusCode,
          statusMessage: mockRes.statusMessage,
          data: responseData,
          headers: Headers.fromMap(
            mockRes.headers.map((k, v) => MapEntry(k, [v])),
          ),
        ),
      );
    } on MockOfflineException catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: e,
          message: e.message,
        ),
      );
    } on MockTimeoutException catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
          error: e,
          message: e.message,
        ),
      );
    } on MockNetworkException catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: e,
          message: e.message,
        ),
      );
    } catch (e) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: e,
          message: e.toString(),
        ),
      );
    }
  }
}
