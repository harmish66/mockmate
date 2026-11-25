import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockmate/mockmate.dart';
import 'package:mockmate_flutter/mockmate_flutter.dart';

void main() {
  group('MockMate Flutter Inspector Tests', () {
    late MockMate mockMate;

    setUp(() {
      mockMate = MockMate(delayProvider: const ZeroDelayProvider());
      mockMate.get(
          '/api/users',
          (req) => MockResponse.json(body: [
                {'id': 1}
              ]));
    });

    tearDown(() {
      mockMate.dispose();
    });

    testWidgets('MockMateInspectorOverlay renders debug button when enabled',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockMateInspectorOverlay(
            mockMate: mockMate,
            enabled: true,
            child: const Scaffold(body: Text('Main Content')),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    });

    testWidgets('MockMateInspectorOverlay hides debug button when disabled',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MockMateInspectorOverlay(
            mockMate: mockMate,
            enabled: false,
            child: const Scaffold(body: Text('Main Content')),
          ),
        ),
      );

      expect(find.text('Main Content'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('MockMateInspectorDialog opens and shows DashboardView',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockMateInspectorDialog(mockMate: mockMate),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MockMate Inspector'), findsOneWidget);
      expect(find.text('System Overview'), findsOneWidget);
      expect(find.text('Total Requests'), findsOneWidget);
      expect(find.text('Active Network Profile'), findsOneWidget);
    });

    testWidgets('Can switch scenarios in ScenariosView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockMateInspectorDialog(mockMate: mockMate, initialIndex: 2),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Global Scenario'), findsOneWidget);
      expect(find.text('offline'), findsOneWidget);

      // Tap 'offline' scenario chip
      await tester.tap(find.text('offline'));
      await tester.pumpAndSettle();

      expect(mockMate.scenarioManager.activeGlobalScenario, equals('offline'));
    });
  });
}
