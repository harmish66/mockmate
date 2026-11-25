import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Command to list registered mock routes from configuration.
class RoutesCommand extends Command<int> {
  RoutesCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output routes list as JSON.',
    );
  }

  @override
  String get name => 'routes';

  @override
  String get description => 'Lists registered mock routes.';

  @override
  Future<int> run() async {
    final asJson = argResults?['json'] == true;
    final configFile = File(p.join('mockmate', 'mockmate.json'));

    if (!await configFile.exists()) {
      stderr.writeln('No mockmate.json found. Run "mockmate init" first.');
      return 1;
    }

    try {
      final content = await configFile.readAsString();
      final dynamic decoded = jsonDecode(content);
      final routes = (decoded is Map && decoded['routes'] is List)
          ? List<Map<String, dynamic>>.from(decoded['routes'] as List)
          : <Map<String, dynamic>>[];

      if (asJson) {
        stdout.writeln(const JsonEncoder.withIndent('  ').convert(routes));
      } else {
        stdout.writeln('Registered Mock Routes (${routes.length}):');
        if (routes.isEmpty) {
          stdout.writeln(' No routes defined in mockmate.json.');
        } else {
          for (final r in routes) {
            final method =
                (r['method'] ?? 'GET').toString().toUpperCase().padRight(7);
            final path = r['path'] ?? '/';
            final status = r['statusCode'] ?? 200;
            stdout.writeln(' $method $path -> $status');
          }
        }
      }
      return 0;
    } catch (e) {
      stderr.writeln('Failed to read routes: $e');
      return 1;
    }
  }
}
