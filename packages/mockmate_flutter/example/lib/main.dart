import 'package:flutter/material.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/mockmate_flutter.dart';

void main() {
  final mockMate = MockMate();

  mockMate.get('/api/greeting', (request) {
    return MockResponse.json(
      body: {'message': 'Hello from MockMate!'},
    );
  });

  runApp(
    MaterialApp(
      home: MockMateInspectorOverlay(
        mockMate: mockMate,
        child: Scaffold(
          appBar: AppBar(title: const Text('MockMate Inspector Example')),
          body: const Center(
            child: Text('Tap the floating bug icon to inspect mock APIs'),
          ),
        ),
      ),
    ),
  );
}
