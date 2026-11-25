import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Command to initialize MockMate configuration and starter directory structure.
class InitCommand extends Command<int> {
  InitCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Force overwrite of existing configuration files.',
    );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initializes MockMate configuration and starter directory structure.';

  @override
  Future<int> run() async {
    final force = argResults?['force'] == true;
    final baseDir = Directory('mockmate');
    final fixturesDir = Directory(p.join('mockmate', 'fixtures'));

    stdout.writeln('Initializing MockMate in current directory...');

    if (await baseDir.exists() && !force) {
      stdout.writeln(
          'Directory "mockmate/" already exists. Use --force to reinitialize.');
      return 0;
    }

    await fixturesDir.create(recursive: true);

    // Create default config file mockmate.json
    final configFile = File(p.join('mockmate', 'mockmate.json'));
    const configContent = '''{
  "version": "0.1.0",
  "fixturesDirectory": "mockmate/fixtures",
  "defaultScenario": "success",
  "network": {
    "profile": "excellent",
    "latencyMinMs": 0,
    "latencyMaxMs": 20,
    "failureRate": 0.0
  },
  "routes": [
    {
      "method": "GET",
      "path": "/api/health",
      "statusCode": 200,
      "response": { "status": "healthy", "service": "mockmate" }
    }
  ]
}
''';
    await configFile.writeAsString(configContent);

    // Create sample fixture file
    final sampleFixture = File(p.join(fixturesDir.path, 'sample_users.json'));
    const fixtureContent = '''[
  { "id": 1, "name": "Ada Lovelace", "role": "Engineer" },
  { "id": 2, "name": "Alan Turing", "role": "Architect" }
]
''';
    await sampleFixture.writeAsString(fixtureContent);

    stdout.writeln('Created mockmate/mockmate.json');
    stdout.writeln('Created mockmate/fixtures/sample_users.json');
    stdout.writeln('MockMate initialization completed successfully.');

    return 0;
  }
}
