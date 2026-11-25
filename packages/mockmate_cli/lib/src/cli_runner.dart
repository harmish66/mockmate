import 'package:args/command_runner.dart';
import 'package:mockmate_cli/src/commands/doctor_command.dart';
import 'package:mockmate_cli/src/commands/export_command.dart';
import 'package:mockmate_cli/src/commands/import_openapi_command.dart';
import 'package:mockmate_cli/src/commands/init_command.dart';
import 'package:mockmate_cli/src/commands/report_command.dart';
import 'package:mockmate_cli/src/commands/routes_command.dart';
import 'package:mockmate_cli/src/commands/scenarios_command.dart';
import 'package:mockmate_cli/src/commands/validate_command.dart';

/// Runner for the MockMate CLI tool.
class MockMateCliRunner extends CommandRunner<int> {
  MockMateCliRunner()
      : super(
          'mockmate',
          'MockMate developer command-line tool for Flutter and Dart API mocking.',
        ) {
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Displays the current version of MockMate CLI.',
    );

    addCommand(InitCommand());
    addCommand(ValidateCommand());
    addCommand(ScenariosCommand());
    addCommand(RoutesCommand());
    addCommand(ImportOpenApiCommand());
    addCommand(ExportCommand());
    addCommand(ReportCommand());
    addCommand(DoctorCommand());
  }

  static const String version = '0.1.0';
}
