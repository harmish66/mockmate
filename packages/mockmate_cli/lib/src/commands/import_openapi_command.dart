import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mockmate/mockmate.dart';
import 'package:path/path.dart' as p;

/// Command to import OpenAPI 3.x specifications into MockMate.
class ImportOpenApiCommand extends Command<int> {
  ImportOpenApiCommand() {
    argParser.addOption(
      'input',
      abbr: 'i',
      mandatory: true,
      help: 'Path to OpenAPI 3.x specification file (JSON format).',
    );
    argParser.addFlag(
      'save-fixtures',
      defaultsTo: true,
      help: 'Save mock response examples into mockmate/fixtures.',
    );
  }

  @override
  String get name => 'import-openapi';

  @override
  String get description =>
      'Imports a supported OpenAPI specification and generates mock route definitions.';

  @override
  Future<int> run() async {
    final inputPath = argResults?['input'] as String;
    final saveFixtures = argResults?['save-fixtures'] == true;

    final file = File(inputPath);
    if (!await file.exists()) {
      stderr.writeln('Specification file not found: $inputPath');
      return 1;
    }

    try {
      final content = await file.readAsString();
      const importer = OpenApiImporter();
      final report = importer.parse(content);

      stdout.writeln('Importing "${report.title}" v${report.version}...');
      stdout.writeln('Found ${report.totalEndpoints} endpoints.');

      final configFile = File(p.join('mockmate', 'mockmate.json'));
      Map<String, dynamic> config = {};
      if (await configFile.exists()) {
        try {
          config = jsonDecode(await configFile.readAsString())
              as Map<String, dynamic>;
        } catch (_) {}
      }

      final existingRoutes =
          List<Map<String, dynamic>>.from(config['routes'] as List? ?? []);
      final fixturesDir = Directory(p.join('mockmate', 'fixtures'));
      if (saveFixtures && !await fixturesDir.exists()) {
        await fixturesDir.create(recursive: true);
      }

      for (final ep in report.endpoints) {
        final defaultRes = ep.responses[200] ?? ep.responses[201];
        final statusCode = defaultRes?.statusCode ?? 200;
        final body = defaultRes?.exampleBody ??
            {'message': 'Mocked ${ep.method.toUpperCase()} ${ep.path}'};

        existingRoutes.add({
          'method': ep.method.toUpperCase(),
          'path': ep.path,
          'statusCode': statusCode,
          'operationId': ep.operationId,
          'summary': ep.summary,
          'response': body,
        });

        if (saveFixtures && ep.operationId != null) {
          final fixFile =
              File(p.join(fixturesDir.path, '${ep.operationId}.json'));
          await fixFile
              .writeAsString(const JsonEncoder.withIndent('  ').convert(body));
        }
      }

      config['routes'] = existingRoutes;
      await configFile.parent.create(recursive: true);
      await configFile
          .writeAsString(const JsonEncoder.withIndent('  ').convert(config));

      stdout.writeln(
          'Successfully generated ${report.totalEndpoints} mock routes in ${configFile.path}.');
      if (report.warnings.isNotEmpty) {
        stdout.writeln('Warnings during import:');
        for (final w in report.warnings) {
          stdout.writeln(' - $w');
        }
      }

      return 0;
    } catch (e) {
      stderr.writeln('OpenAPI import failed: $e');
      return 1;
    }
  }
}
