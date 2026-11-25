import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Command to validate MockMate configuration, routes, and JSON fixtures.
class ValidateCommand extends Command<int> {
  ValidateCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output validation result as formatted JSON.',
    );
  }

  @override
  String get name => 'validate';

  @override
  String get description =>
      'Validates routes, fixtures, and scenarios in the current project.';

  @override
  Future<int> run() async {
    final asJson = argResults?['json'] == true;
    final errors = <String>[];
    final warnings = <String>[];

    final configFile = File(p.join('mockmate', 'mockmate.json'));
    if (!await configFile.exists()) {
      errors.add(
          'Missing configuration file: ${configFile.path}. Run "mockmate init" first.');
    } else {
      try {
        final content = await configFile.readAsString();
        final dynamic decoded = jsonDecode(content);
        if (decoded is! Map<String, dynamic>) {
          errors.add('mockmate.json must be a JSON object.');
        } else {
          if (!decoded.containsKey('routes') || decoded['routes'] is! List) {
            warnings.add('No routes array declared in mockmate.json.');
          }
        }
      } catch (e) {
        errors.add('Failed to parse mockmate.json: $e');
      }
    }

    // Validate fixtures
    final fixturesDir = Directory(p.join('mockmate', 'fixtures'));
    var validFixturesCount = 0;
    if (await fixturesDir.exists()) {
      await for (final file in fixturesDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final content = await file.readAsString();
            jsonDecode(content);
            validFixturesCount++;
          } catch (e) {
            errors.add('Invalid JSON in fixture ${file.path}: $e');
          }
        }
      }
    }

    final isValid = errors.isEmpty;

    if (asJson) {
      final report = {
        'valid': isValid,
        'errors': errors,
        'warnings': warnings,
        'fixturesValidated': validFixturesCount,
      };
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(report));
    } else {
      if (isValid) {
        stdout.writeln('Validation passed.');
        stdout.writeln(
            'Validated $validFixturesCount fixture files successfully.');
        if (warnings.isNotEmpty) {
          stdout.writeln('Warnings:');
          for (final w in warnings) {
            stdout.writeln(' - $w');
          }
        }
      } else {
        stderr.writeln('Validation failed with ${errors.length} error(s):');
        for (final e in errors) {
          stderr.writeln(' [ERROR] $e');
        }
      }
    }

    return isValid ? 0 : 1;
  }
}
