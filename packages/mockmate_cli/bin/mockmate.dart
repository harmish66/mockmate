import 'dart:io';
import 'package:mockmate_cli/src/cli_runner.dart';

Future<void> main(List<String> args) async {
  final runner = MockMateCliRunner();

  if (args.contains('--version') || args.contains('-v')) {
    stdout.writeln('mockmate version ${MockMateCliRunner.version}');
    exit(0);
  }

  try {
    final exitCode = await runner.run(args) ?? 0;
    exit(exitCode);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
