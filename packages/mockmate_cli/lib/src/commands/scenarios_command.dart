import 'dart:convert';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mockmate/mockmate.dart';
import 'package:path/path.dart' as p;

/// Command to list configured scenarios.
class ScenariosCommand extends Command<int> {
  ScenariosCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output scenarios as JSON.',
    );
  }

  @override
  String get name => 'scenarios';

  @override
  String get description => 'Lists available and configured scenarios.';

  @override
  Future<int> run() async {
    final asJson = argResults?['json'] == true;
    final scenarios = List<String>.from(ScenarioNames.allStandard);

    final configFile = File(p.join('mockmate', 'mockmate.json'));
    var defaultScenario = 'success';

    if (await configFile.exists()) {
      try {
        final content = await configFile.readAsString();
        final dynamic decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('defaultScenario')) {
          defaultScenario = decoded['defaultScenario'].toString();
        }
      } catch (_) {}
    }

    if (asJson) {
      final map = {
        'defaultScenario': defaultScenario,
        'standardScenarios': scenarios,
      };
      stdout.writeln(const JsonEncoder.withIndent('  ').convert(map));
    } else {
      stdout.writeln('Default Scenario: $defaultScenario');
      stdout.writeln('Available Scenarios:');
      for (final s in scenarios) {
        final isDefault = s == defaultScenario ? ' (default)' : '';
        stdout.writeln(' - $s$isDefault');
      }
    }

    return 0;
  }
}
