import 'package:mockmate/mockmate.dart';

void main() async {
  final mockMate = MockMate();

  // 1. Register a mock GET endpoint
  mockMate.get('/api/users', (request) {
    return MockResponse.json(
      statusCode: 200,
      body: [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ],
    );
  });

  // 2. Register stateful CRUD resource
  mockMate.resource(
    '/api/products',
    initialData: [
      {'id': 1, 'name': 'Laptop', 'price': 999.99},
    ],
  );

  // 3. Handle request
  final response = await mockMate.handleRequest(
    MockRequest(
      method: HttpMethod.get,
      uri: Uri.parse('http://localhost/api/users'),
    ),
  );

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.bodyAsString}');

  mockMate.dispose();
}
