import 'dart:convert';
import 'package:mockmate/mockmate.dart';

void main() async {
  print('--- MockMate package:http Adapter Example ---');

  // 1. Create MockMate engine
  final mockMate = MockMate();

  // 2. Register mock endpoints
  mockMate.get('/api/settings', (request) {
    return MockResponse.json(
      body: {
        'theme': 'dark',
        'notifications': true,
        'version': '1.0.0',
      },
    );
  });

  // 3. Create HTTP client with MockMate adapter
  final client = MockMateHttpClient(mockMate: mockMate);

  // 4. Fetch data via standard package:http
  print('\n[HTTP GET https://myapp.com/api/settings]');
  final response =
      await client.get(Uri.parse('https://myapp.com/api/settings'));

  print('Status code: ${response.statusCode}');
  print('Headers: ${response.headers}');
  print('Body: ${response.body}');

  final decoded = jsonDecode(response.body);
  print('Parsed JSON Theme: ${decoded["theme"]}');

  client.close();
  mockMate.dispose();
  print('\n--- package:http Example Completed Successfully ---');
}
