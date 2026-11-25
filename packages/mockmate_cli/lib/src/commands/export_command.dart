import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Command to export all MockMate configurations and fixtures to a single portable bundle.
class ExportCommand extends Command<int> {
  ExportCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'mockmate_export.json',
      help: 'Target file path for the exported bundle.',
    );
  }

  @override
  String get name => 'export';

  @override
  String get description =>
      'Exports configuration and fixtures into a portable bundle.';

  @override
  Future<int> run() async {
    final outputPath = argResults?['output'] as String;
    final configFile = File(p.join('mockmate', 'mockmate.json'));
    final fixturesDir = Directory(p.join('mockmate', 'fixtures'));

    Map<String, dynamic> config = {};
    if (await configFile.exists()) {
      try {
        config =
            jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }

    final fixtures = <String, dynamic>{};
    if (await fixturesDir.exists()) {
      await for (final file in fixturesDir.list(recursive: true)) {
        if (file is File && file.path.endsWith('.json')) {
          final relName = p.relative(file.path, from: fixturesDir.path);
          try {
            fixtures[relName] = jsonDecode(await file.readAsString());
          } catch (_) {}
        }
      }
    }

    final exportBundle = {
      'exportedAt': DateTime.now().toIso8601String(),
      'config': config,
      'fixtures': fixtures,
    };

    final outFile = File(outputPath);
    await outFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportBundle));

    stdout.writeln('Successfully exported MockMate bundle to $outputPath');
    stdout.writeln('Contains config and ${fixtures.length} fixture file(s).');

    return 0;
  }
}
