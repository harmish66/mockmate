import 'package:dio/dio.dart';
import 'package:mockmate/mockmate.dart';

void main() async {
  print('--- MockMate Dio Adapter Example ---');

  // 1. Create MockMate engine
  final mockMate = MockMate();

  // 2. Register mock endpoints
  mockMate.get('/api/posts', (request) {
    return MockResponse.json(
      statusCode: 200,
      body: [
        {'id': 101, 'title': 'Learning Dart with MockMate'},
        {'id': 102, 'title': 'Zero Backend Flutter Testing'},
      ],
    );
  });

  mockMate.post('/api/posts', (request) {
    final body = request.bodyAsJson as Map<String, dynamic>? ?? {};
    return MockResponse.json(
      statusCode: 201,
      body: {
        'id': 103,
        'title': body['title'] ?? 'Untitled',
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  });

  // 3. Configure Dio with MockMate interceptor
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.interceptors.add(MockMateDioAdapter(mockMate));

  // 4. Make requests using standard Dio API
  print('\n[Dio GET /api/posts]');
  final listRes = await dio.get<List<dynamic>>('/api/posts');
  print('Status: ${listRes.statusCode}');
  print('Data: ${listRes.data}');

  print('\n[Dio POST /api/posts]');
  final createRes = await dio.post<Map<String, dynamic>>(
    '/api/posts',
    data: {'title': 'Full-stack testing with MockMate'},
  );
  print('Status: ${createRes.statusCode}');
  print('Created Data: ${createRes.data}');

  print('\nRecorded Transactions: ${mockMate.requestHistory.length}');
  mockMate.dispose();
  print('\n--- Dio Example Completed Successfully ---');
}
