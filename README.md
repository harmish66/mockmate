# MockMate

Build without backend. Test without limits.

MockMate is a complete API mocking, testing, network simulation, and inspection ecosystem for Flutter and Dart applications.

It enables developers to build and test applications before a backend exists, simulate tough network edge cases (slow 3G, server crashes, timeouts, offline connectivity), and inspect live API traffic with a visual Flutter dashboard.

---

## Ecosystem Packages

The MockMate repository is structured as a monorepo containing three modular packages:

| Package | pub.dev | Description |
| :--- | :--- | :--- |
| **[`mockmate`](packages/mockmate)** | [![pub package](https://img.shields.io/pub/v/mockmate.svg)](https://pub.dev/packages/mockmate) | Pure Dart core mocking engine, network simulator, stateful in-memory database, and adapters for `Dio` and `package:http`. Zero Flutter dependencies. |
| **[`mockmate_flutter`](packages/mockmate_flutter)** | [![pub package](https://img.shields.io/pub/v/mockmate_flutter.svg)](https://pub.dev/packages/mockmate_flutter) | Developer inspection dashboard and floating overlay for Flutter applications. |
| **[`mockmate_cli`](packages/mockmate_cli)** | [![pub package](https://img.shields.io/pub/v/mockmate_cli.svg)](https://pub.dev/packages/mockmate_cli) | Command-line developer tool for project setup, route validation, and OpenAPI 3.x imports. |

---

## Architecture at a Glance

```
                +---------------------------------------+
                |           Flutter / Dart App          |
                |  (Dio, package:http, or MockRequest)  |
                +---------------------------------------+
                                   |
                                   v
                +---------------------------------------+
                |        MockMate Core Engine           |
                |                                       |
                |  1. Network Simulator (latency, drop) |
                |  2. Scenario Engine (empty, 500, etc) |
                |  3. Router (exact, :id, *, query)     |
                |  4. Stateful DB (CRUD, sort, filter)  |
                |  5. Traffic Recorder & Replay Engine  |
                +---------------------------------------+
                       |                        |
                       v                        v
        +----------------------------+   +-----------------------------+
        |   MockMate Visual UI       |   |       MockMate CLI          |
        |  (mockmate_flutter overlay)|   |  (routes, validate, OpenAPI)|
        +----------------------------+   +-----------------------------+
```

---

## 5-Minute Quick Start

### 1. Add Dependencies

Add the packages to your Flutter app:

```yaml
dependencies:
  mockmate: ^0.1.1

dev_dependencies:
  mockmate_flutter: ^0.1.1
```

### 2. Set Up Mock Endpoints in Your App

Initialize `MockMate` in `main.dart` and wrap your app with `MockMateInspectorOverlay`:

```dart
import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/mockmate_flutter.dart';

void main() {
  final mockMate = MockMate();

  // Create a full stateful CRUD API in one line
  mockMate.resource(
    '/api/products',
    initialData: [
      {'id': 1, 'name': 'Wireless Headphones', 'price': 199.99},
      {'id': 2, 'name': 'Mechanical Keyboard', 'price': 149.00},
    ],
  );

  // Define testing scenarios
  mockMate.scenario('products', {
    'success': MockResponse.json(body: [{'id': 1, 'name': 'Item'}]),
    'empty': MockResponse.json(body: []),
    'serverError': MockResponse.error(statusCode: 500, message: 'Server down'),
  });

  runApp(
    MaterialApp(
      home: MockMateInspectorOverlay(
        mockMate: mockMate,
        child: const ProductCatalogScreen(),
      ),
    ),
  );
}
```

### 3. Connect to Your HTTP Client

#### With Dio:
```dart
final dio = Dio();
dio.interceptors.add(MockMateDioAdapter(mockMate));
```

#### With package:http:
```dart
final client = MockMateHttpClient(mockMate: mockMate);
final response = await client.get(Uri.parse('https://example.com/api/products'));
```

---

## Working Examples

The repository includes four complete, runnable example projects:

- **[`examples/basic_example`](examples/basic_example):** Pure Dart example demonstrating routing, path parameters, and scenario switching.
- **[`examples/dio_example`](examples/dio_example):** Demonstrating `MockMateDioAdapter` interceptor with error handling.
- **[`examples/http_example`](examples/http_example):** Demonstrating `MockMateHttpClient` with `package:http`.
- **[`examples/ecommerce_example`](examples/ecommerce_example):** A complete Flutter shopping app featuring catalog browsing, item creation, editing, deleting, empty states, error handling, offline mode, and the visual inspector overlay.

Run any example directly:

```bash
# Basic Dart example
dart run examples/basic_example/bin/main.dart

# Dio adapter example
dart run examples/dio_example/bin/main.dart

# package:http example
dart run examples/http_example/bin/main.dart

# Flutter ecommerce application
cd examples/ecommerce_example && flutter run
```

---

## Running Automated Tests

All packages are covered with automated tests with zero live network dependencies:

```bash
# Core engine tests (25 tests covering routing, DB, latency, Dio, HTTP)
cd packages/mockmate && dart test

# Visual inspector widget tests
cd packages/mockmate_flutter && flutter test

# CLI command tests
cd packages/mockmate_cli && dart test

# Ecommerce app integration tests
cd examples/ecommerce_example && flutter test
```

---

## Documentation Links

- [Architecture & Design Decisions](docs/architecture.md)
- [MockMate Core Package Guide](packages/mockmate/README.md)
- [MockMate Flutter Inspector Guide](packages/mockmate_flutter/README.md)
- [MockMate CLI Guide](packages/mockmate_cli/README.md)

---

## License

BSD-3-Clause License. See the [LICENSE](LICENSE) file for details.
