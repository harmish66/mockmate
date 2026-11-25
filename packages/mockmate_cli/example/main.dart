// Example of running MockMate CLI commands programmatically or via shell:
//
// 1. Initialize MockMate in your project:
//    dart run mockmate_cli init
//
// 2. Validate mock routes and fixtures:
//    dart run mockmate_cli validate
//
// 3. Check environment health:
//    dart run mockmate_cli doctor
//
// 4. Import OpenAPI specification:
//    dart run mockmate_cli import-openapi -i openapi_spec.json

import 'package:mockmate_cli/mockmate_cli.dart';

Future<void> main(List<String> args) async {
  final runner = MockMateCliRunner();
  await runner.run(['doctor']);
}
