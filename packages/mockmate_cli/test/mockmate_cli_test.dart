import 'dart:io';
import 'package:mockmate_cli/mockmate_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('MockMate CLI Commands', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mockmate_cli_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Doctor command runs cleanly', () async {
      final runner = MockMateCliRunner();
      final exitCode = await runner.run(['doctor']);
      expect(exitCode, equals(0));
    });

    test('Init command creates mockmate.json and sample fixtures', () async {
      final runner = MockMateCliRunner();
      final currentDir = Directory.current;

      try {
        Directory.current = tempDir.path;
        final exitCode = await runner.run(['init']);
        expect(exitCode, equals(0));

        final configFile =
            File(p.join(tempDir.path, 'mockmate', 'mockmate.json'));
        final fixtureFile = File(
            p.join(tempDir.path, 'mockmate', 'fixtures', 'sample_users.json'));

        expect(await configFile.exists(), isTrue);
        expect(await fixtureFile.exists(), isTrue);

        // Validate command should pass
        final validateExitCode = await runner.run(['validate']);
        expect(validateExitCode, equals(0));

        // Scenarios command
        final scenariosExitCode = await runner.run(['scenarios']);
        expect(scenariosExitCode, equals(0));

        // Routes command
        final routesExitCode = await runner.run(['routes']);
        expect(routesExitCode, equals(0));

        // Report command
        final reportExitCode = await runner.run(['report']);
        expect(reportExitCode, equals(0));

        // Export command
        final exportExitCode =
            await runner.run(['export', '-o', 'bundle.json']);
        expect(exportExitCode, equals(0));
        expect(
            await File(p.join(tempDir.path, 'bundle.json')).exists(), isTrue);
      } finally {
        Directory.current = currentDir.path;
      }
    });

    test('Import OpenAPI command parses and adds routes', () async {
      final runner = MockMateCliRunner();
      final currentDir = Directory.current;

      try {
        Directory.current = tempDir.path;
        await runner.run(['init']);

        final specFile = File(p.join(tempDir.path, 'openapi.json'));
        await specFile.writeAsString('''{
          "openapi": "3.0.0",
          "info": { "title": "Store API", "version": "1.0.0" },
          "paths": {
            "/api/orders": {
              "get": {
                "summary": "Get orders",
                "responses": {
                  "200": {
                    "description": "Orders list",
                    "content": {
                      "application/json": {
                        "example": [{"orderId": 101, "total": 45.5}]
                      }
                    }
                  }
                }
              }
            }
          }
        }''');

        final importExitCode =
            await runner.run(['import-openapi', '-i', specFile.path]);
        expect(importExitCode, equals(0));

        // Routes command should list /api/orders
        final routesExitCode = await runner.run(['routes', '--json']);
        expect(routesExitCode, equals(0));
      } finally {
        Directory.current = currentDir.path;
      }
    });
  });
}
