import 'package:mockmate/mockmate.dart';

void main() async {
  print('--- MockMate Basic Example ---');

  // 1. Initialize MockMate engine
  final mock = MockMate();

  // 2. Register mock GET endpoint
  mock.get('/api/users', (req) {
    return MockResponse.json(
      statusCode: 200,
      body: {
        'success': true,
        'users': [
          {'id': 1, 'name': 'Harmish'},
          {'id': 2, 'name': 'Sarah'},
        ],
      },
    );
  });

  // 3. Register route with path parameters
  mock.get('/api/users/:id', (req) {
    final id = req.pathParameters['id'];
    return MockResponse.json(
      statusCode: 200,
      body: {'id': id, 'name': 'User #$id'},
    );
  });

  // 4. Configure scenarios
  mock.scenario('users', {
    'success': MockResponse.json(body: {'status': 'all users returned'}),
    'empty':
        MockResponse.json(body: {'status': 'no users available', 'users': []}),
    'serverError': MockResponse.error(
        statusCode: 500, message: 'Database connection failed'),
  });

  // 5. Test request execution
  print('\n[Request 1]: GET /api/users');
  final res1 = await mock.handleRequest(
    MockRequest(
        method: HttpMethod.get, uri: Uri.parse('http://localhost/api/users')),
  );
  print('Status: ${res1.statusCode}');
  print('Body: ${res1.bodyAsString}');

  print('\n[Request 2]: GET /api/users/99');
  final res2 = await mock.handleRequest(
    MockRequest(
        method: HttpMethod.get,
        uri: Uri.parse('http://localhost/api/users/99')),
  );
  print('Status: ${res2.statusCode}');
  print('Body: ${res2.bodyAsString}');

  // 6. Switch to empty scenario
  print('\n[Switching to "empty" scenario]');
  mock.activateRouteScenario('users', 'empty');
  final res3 = await mock.handleRequest(
    MockRequest(
        method: HttpMethod.get, uri: Uri.parse('http://localhost/api/users')),
  );
  print('Status: ${res3.statusCode}');
  print('Body: ${res3.bodyAsString}');

  mock.dispose();
  print('\n--- Basic Example Completed Successfully ---');
}
