import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Command to generate a comprehensive validation and summary report.
class ReportCommand extends Command<int> {
  ReportCommand() {
    argParser.addOption(
      'format',
      abbr: 'f',
      allowed: ['markdown', 'json'],
      defaultsTo: 'markdown',
      help: 'Output report format.',
    );
  }

  @override
  String get name => 'report';

  @override
  String get description =>
      'Generates a validation and mock configuration summary report.';

  @override
  Future<int> run() async {
    final format = argResults?['format'] as String;
    final configFile = File(p.join('mockmate', 'mockmate.json'));
    final fixturesDir = Directory(p.join('mockmate', 'fixtures'));

    Map<String, dynamic> config = {};
    if (await configFile.exists()) {
      try {
        config =
            jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }

    final routes = config['routes'] as List? ?? [];
    final fixtureFiles = <String>[];
    if (await fixturesDir.exists()) {
      await for (final file in fixturesDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.json')) {
          fixtureFiles.add(p.relative(file.path));
        }
      }
    }

    if (format == 'json') {
      final jsonReport = {
        'timestamp': DateTime.now().toIso8601String(),
        'configFound': await configFile.exists(),
        'routesCount': routes.length,
        'fixturesCount': fixtureFiles.length,
        'fixtureFiles': fixtureFiles,
        'routes': routes,
      };
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(jsonReport));
    } else {
      final sb = StringBuffer()
        ..writeln('# MockMate Validation & Summary Report')
        ..writeln()
        ..writeln('Generated: ${DateTime.now().toIso8601String()}')
        ..writeln()
        ..writeln('## Configuration Status')
        ..writeln(
            '- Config file: ${await configFile.exists() ? "Found (mockmate/mockmate.json)" : "Missing"}')
        ..writeln('- Total Mock Routes: ${routes.length}')
        ..writeln('- Total Fixture Files: ${fixtureFiles.length}')
        ..writeln()
        ..writeln('## Registered Routes');

      if (routes.isEmpty) {
        sb.writeln('No routes defined.');
      } else {
        for (final r in routes) {
          if (r is Map) {
            sb.writeln(
                '- **${r["method"] ?? "GET"}** `${r["path"] ?? "/"}` -> status ${r["statusCode"] ?? 200}');
          }
        }
      }

      sb.writeln();
      sb.writeln('## Fixtures on Disk');
      if (fixtureFiles.isEmpty) {
        sb.writeln('No fixture files found.');
      } else {
        for (final f in fixtureFiles) {
          sb.writeln('- `$f`');
        }
      }

      stdout.writeln(sb.toString());
    }

    return 0;
  }
}
