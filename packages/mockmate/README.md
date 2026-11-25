# MockMate

Build without backend. Test without limits.

MockMate is an API mocking and network simulation toolkit for Flutter and Dart applications. It lets developers build, test, and debug user interfaces before the backend exists, and simulate difficult edge cases like network timeouts, server failures, and offline connectivity.

---

## Why MockMate?

Frontend development often gets blocked when:
- Backend endpoints are still under construction or changing.
- Testing error states (500 Internal Server Error, 401 Unauthorized) requires breaking real servers.
- Testing slow networks or offline behavior requires manual device toggling.
- Unit and integration tests rely on live network calls that are slow or flaky.

MockMate provides a local, in-memory mocking environment that works with your existing HTTP code (`Dio` and `package:http`) without modifying your application logic.

---

## Features

- **Route Matching:** Exact paths, path parameters (`/users/:id`), wildcards (`/assets/*`), query parameters, and headers.
- **Realistic Responses:** Strongly-typed builders for JSON, plain text, raw bytes, empty responses, and error codes.
- **Scenario Engine:** Toggle between `success`, `loading`, `empty`, `unauthorized`, `forbidden`, `notFound`, and `serverError` at runtime.
- **Network Simulator:** Simulate latency ranges, random failures, timeouts, and offline conditions with zero external dependencies.
- **Stateful In-Memory Database:** Complete REST CRUD resources with sorting, searching, filtering, and pagination out of the box.
- **Traffic Recorder and Replay:** Automatically record requests and responses with built-in credential redaction, and replay transactions.
- **Client Adapters:** Drop-in interceptor for `Dio` and custom client for `package:http`.
- **OpenAPI 3.x Support:** Generate mock routes directly from OpenAPI specification files.
- **Testing Assertions:** Custom test matcher `hasRequested()` for clean unit tests.

---

## Installation

Add `mockmate` to your `pubspec.yaml`:

```yaml
dependencies:
  mockmate: ^0.1.1
```

Or run:

```bash
dart pub add mockmate
```

---

## Beginner Guide and Common Examples

### 1. Basic Route Registration

Create a `MockMate` instance and define endpoints:

```dart
import 'package:mockmate/mockmate.dart';

void main() async {
  final mockMate = MockMate();

  // Simple GET endpoint returning JSON
  mockMate.get('/api/users', (request) {
    return MockResponse.json(
      statusCode: 200,
      body: [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ],
    );
  });

  // Dynamic path parameter (:id)
  mockMate.get('/api/users/:id', (request) {
    final userId = request.pathParameters['id'];
    return MockResponse.json(
      statusCode: 200,
      body: {'id': userId, 'name': 'User $userId'},
    );
  });

  // Execute request directly
  final response = await mockMate.handleRequest(
    MockRequest(method: HttpMethod.get, uri: Uri.parse('http://localhost/api/users/42')),
  );

  print(response.bodyAsString); // {"id":"42","name":"User 42"}
  mockMate.dispose();
}
```

---

### 2. Using with Dio

If your project uses `Dio`, add `MockMateDioAdapter` as an interceptor. Your existing API calls will automatically resolve against MockMate:

```dart
import 'package:dio/dio.dart';
import 'package:mockmate/mockmate.dart';

void main() async {
  final mockMate = MockMate();

  // Define mock routes
  mockMate.get('/api/posts', (request) {
    return MockResponse.json(
      statusCode: 200,
      body: [
        {'id': 101, 'title': 'First Post'},
      ],
    );
  });

  // Configure Dio
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
  dio.interceptors.add(MockMateDioAdapter(mockMate));

  // Make normal requests via Dio
  final response = await dio.get<dynamic>('/api/posts');
  print(response.data);
}
```

---

### 3. Using with package:http

If your project uses `package:http`, wrap requests with `MockMateHttpClient`:

```dart
import 'package:mockmate/mockmate.dart';

void main() async {
  final mockMate = MockMate();

  mockMate.get('/api/status', (request) {
    return MockResponse.json(body: {'status': 'healthy'});
  });

  // Use as a standard http.Client
  final client = MockMateHttpClient(mockMate: mockMate);
  final response = await client.get(Uri.parse('https://example.com/api/status'));

  print(response.body); // {"status":"healthy"}
  client.close();
}
```

---

### 4. Stateful REST CRUD with Mock Database

Need a full backend for a resource? `mockMate.resource()` automatically creates GET (list & by ID), POST (create), PUT (replace), PATCH (update), and DELETE endpoints with query filtering, sorting, and pagination:

```dart
final mockMate = MockMate();

// Automatically creates:
// GET    /api/products          (list, search, filter, pagination, sort)
// GET    /api/products/:id      (get by id)
// POST   /api/products          (create item)
// PUT    /api/products/:id      (replace item)
// PATCH  /api/products/:id      (update fields)
// DELETE /api/products/:id      (delete item)
mockMate.resource(
  '/api/products',
  initialData: [
    {'id': 1, 'name': 'Laptop', 'price': 999.99, 'category': 'tech'},
    {'id': 2, 'name': 'Chair', 'price': 199.99, 'category': 'furniture'},
  ],
);

// Filter by category: GET /api/products?category=tech
// Search keyword:      GET /api/products?q=chair
// Sort:                GET /api/products?sort=price&order=desc
// Paginate:            GET /api/products?page=1&limit=10
```

---

### 5. Testing Scenarios (Success, Empty, Server Error)

Define multiple response variations for an endpoint and switch between them at runtime to test different UI states:

```dart
final mockMate = MockMate();

mockMate.scenario('products', {
  'success': MockResponse.json(
    statusCode: 200,
    body: [{'id': 1, 'name': 'Headphones'}],
  ),
  'empty': MockResponse.json(
    statusCode: 200,
    body: [],
  ),
  'serverError': MockResponse.error(
    statusCode: 500,
    message: 'Internal Database Error',
  ),
  'unauthorized': MockResponse.json(
    statusCode: 401,
    body: {'error': 'Session expired'},
  ),
});

// Switch active scenario
mockMate.activateRouteScenario('products', 'empty');
// Now any request to /api/products returns []

mockMate.activateRouteScenario('products', 'serverError');
// Now requests return 500 status code
```

---

### 6. Simulating Network Conditions

Simulate spotty WiFi, slow 2G, timeouts, or complete offline states:

```dart
final mockMate = MockMate();

// Use preset profile: excellent, good, average, poor, offline
mockMate.network.setProfile(NetworkProfile.poor);

// Or simulate complete offline mode:
mockMate.network.setOffline(true);

// Re-enable normal connectivity:
mockMate.network.setOffline(false);
```

---

### 7. Unit Testing with Custom Matchers

MockMate provides `ZeroDelayProvider` for instant test execution and `hasRequested()` for verifying network calls:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockmate/mockmate.dart';

void main() {
  test('fetches items and verifies request', () async {
    // ZeroDelayProvider eliminates wait times in unit tests
    final mockMate = MockMate(delayProvider: const ZeroDelayProvider());

    mockMate.get('/api/items', (req) => MockResponse.json(body: ['item1']));

    final response = await mockMate.handleRequest(
      MockRequest(method: HttpMethod.get, uri: Uri.parse('http://localhost/api/items')),
    );

    expect(response.statusCode, equals(200));

    // Verify that the request was captured by MockMate
    expect(mockMate, hasRequested(path: '/api/items', method: HttpMethod.get, count: 1));

    mockMate.dispose();
  });
}
```

---

## Security and Credential Redaction

MockMate is designed for secure development. By default, the request recorder automatically redacts sensitive headers and body fields (like `authorization`, `cookie`, `x-api-key`, `password`, `token`, `secret`, `ssn`) so credentials are never exposed in logs or inspector views.

---

## License

BSD-3-Clause License. See the LICENSE file for details.
