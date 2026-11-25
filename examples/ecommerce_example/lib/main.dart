import 'package:ecommerce_example/screens/product_list_screen.dart';
import 'package:ecommerce_example/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/mockmate_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize MockMate engine
  final mockMate = MockMate();

  // 2. Register stateful in-memory products resource with seed data
  mockMate.resource(
    '/api/products',
    initialData: [
      {
        'id': 1,
        'name': 'Wireless Noise-Canceling Headphones',
        'category': 'Audio',
        'price': 199.99,
        'stock': 24,
        'description':
            'High-fidelity audio with active noise cancellation and 30-hour battery life.',
      },
      {
        'id': 2,
        'name': 'Mechanical Ergonomic Keyboard',
        'category': 'Accessories',
        'price': 149.00,
        'stock': 12,
        'description':
            'Compact wireless mechanical keyboard with hot-swappable switches.',
      },
      {
        'id': 3,
        'name': 'Ultra-Wide 4K Gaming Monitor',
        'category': 'Electronics',
        'price': 699.99,
        'stock': 8,
        'description':
            '34-inch curved display with 144Hz refresh rate and HDR 600.',
      },
      {
        'id': 4,
        'name': 'Precision Wireless Mouse',
        'category': 'Accessories',
        'price': 79.50,
        'stock': 35,
        'description':
            'High-precision optical sensor with rechargeable USB-C battery.',
      },
    ],
  );

  // 3. Define scenarios for testing loading, empty, and serverError states
  mockMate.scenario('products', {
    'success': MockResponse.json(
      statusCode: 200,
      body: {
        'total': 4,
        'data': [
          {
            'id': 1,
            'name': 'Wireless Noise-Canceling Headphones',
            'category': 'Audio',
            'price': 199.99,
            'stock': 24,
            'description':
                'High-fidelity audio with active noise cancellation.',
          },
        ],
      },
    ),
    'empty': MockResponse.json(
      statusCode: 200,
      body: {'total': 0, 'data': []},
    ),
    'serverError': MockResponse.error(
      statusCode: 500,
      message: 'Database connection failed',
    ),
  });

  runApp(MockMateEcommerceApp(mockMate: mockMate));
}

class MockMateEcommerceApp extends StatelessWidget {
  const MockMateEcommerceApp({super.key, required this.mockMate});

  final MockMate mockMate;

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(mockMate);

    return MaterialApp(
      title: 'MockMate Ecommerce',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: MockMateInspectorOverlay(
        mockMate: mockMate,
        enabled: true,
        child: ProductListScreen(
          apiService: apiService,
          onOpenInspector: () {
            MockMateInspectorDialog.show(context, mockMate: mockMate);
          },
        ),
      ),
    );
  }
}
