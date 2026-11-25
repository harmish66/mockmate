# MockMate Flutter Inspector

A visual debugging dashboard and floating overlay for MockMate in Flutter applications.

Inspect API traffic, switch backend scenarios live, simulate network latency and offline modes, and replay requests directly on your device or simulator without touching code.

---

## Features

- **Floating Debug Button:** A draggable launcher button that stays accessible across all app screens in debug mode.
- **Traffic Dashboard:** Real-time metrics for total requests, success rates, server errors, and average latency.
- **Request Explorer:** Inspect HTTP methods, URL paths, status badges, and search/filter by status or method.
- **JSON Inspector:** Syntax-formatted JSON viewer with one-click copy to clipboard for headers and payloads.
- **Live Scenario Switcher:** Switch between `success`, `empty`, `serverError`, `unauthorized`, or `offline` with one tap to test UI edge cases instantly.
- **Network Simulation Controls:** Sliders to adjust minimum/maximum latency, failure probabilities, and a quick toggle for offline mode.
- **Request Replay Workspace:** Edit request parameters or JSON bodies and replay transactions to verify how your app reacts.
- **Credential Redaction:** Masks passwords, authorization tokens, and API keys automatically.

---

## Installation

Add `mockmate_flutter` and `mockmate` to your `pubspec.yaml`:

```yaml
dependencies:
  mockmate: ^0.1.1
  mockmate_flutter: ^0.1.1
```

Or run:

```bash
flutter pub add mockmate mockmate_flutter
```

---

## Quick Start

### 1. Add Overlay to Your App

Wrap your app with `MockMateInspectorOverlay`. It automatically shows the floating bug icon in debug builds and stays completely hidden in production builds:

```dart
import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/mockmate_flutter.dart';

void main() {
  // 1. Initialize MockMate engine
  final mockMate = MockMate();

  // 2. Define mock routes or stateful resources
  mockMate.resource(
    '/api/products',
    initialData: [
      {'id': 1, 'name': 'Noise-Canceling Headphones', 'price': 199.99},
      {'id': 2, 'name': 'Ergonomic Keyboard', 'price': 149.00},
    ],
  );

  // 3. Define scenarios
  mockMate.scenario('products', {
    'success': MockResponse.json(body: [{'id': 1, 'name': 'Item'}]),
    'empty': MockResponse.json(body: []),
    'serverError': MockResponse.error(statusCode: 500, message: 'Server Down'),
  });

  runApp(MyApp(mockMate: mockMate));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.mockMate});

  final MockMate mockMate;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MockMateInspectorOverlay(
        mockMate: mockMate,
        // enabled defaults to kDebugMode so it never shows in release builds
        child: const ProductCatalogScreen(),
      ),
    );
  }
}
```

---

### 2. Opening the Inspector Programmatically

You can also open the inspector from a settings screen or custom debug menu using `MockMateInspectorDialog.show`:

```dart
IconButton(
  icon: const Icon(Icons.bug_report),
  tooltip: 'Open Inspector',
  onPressed: () {
    MockMateInspectorDialog.show(context, mockMate: mockMate);
  },
)
```

---

## Inspector Tabs

1. **Dashboard:** Displays overall API health, total request volume, success percentage, error count, and current active network profile.
2. **Requests:** Scroll through recorded HTTP calls, filter by HTTP verb (`GET`, `POST`, `PUT`, `DELETE`), or filter by `Errors Only`.
3. **Request Details:** Tabbed interface with Request Body, Response Body, Headers table, and Diagnostics.
4. **Scenarios:** Tap any standard scenario chip (`success`, `loading`, `empty`, `unauthorized`, `serverError`, `offline`) or route-specific dropdowns to switch backend responses immediately.
5. **Network:** Test how your app handles 3G/2G speeds by picking presets (`Average`, `Poor`) or dragging latency sliders up to 5000ms.
6. **Replay:** Choose any previous request, tweak the URL or body, and tap `Replay Request` to test backend validation.
7. **Settings:** Toggle traffic recording, clear request history, or copy the full transaction history as JSON.

---

## License

BSD-3-Clause License. See the LICENSE file for details.
