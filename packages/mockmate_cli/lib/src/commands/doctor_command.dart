import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

/// Command to verify environment, configuration, and tools.
class DoctorCommand extends Command<int> {
  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Checks environment, configuration files, and permissions.';

  @override
  Future<int> run() async {
    stdout.writeln('Checking MockMate development environment...');
    stdout.writeln();

    var hasErrors = false;

    // 1. Dart SDK check
    stdout.writeln('[OK] Dart SDK: ${Platform.version.split(' ').first}');

    // 2. MockMate directory check
    final mockmateDir = Directory('mockmate');
    if (await mockmateDir.exists()) {
      stdout.writeln('[OK] Project directory: mockmate/ exists');
    } else {
      stdout.writeln(
          '[WARN] Project directory: mockmate/ missing (run "mockmate init")');
    }

    // 3. Config check
    final configFile = File(p.join('mockmate', 'mockmate.json'));
    if (await configFile.exists()) {
      stdout.writeln('[OK] Configuration: mockmate/mockmate.json present');
    } else {
      stdout.writeln('[WARN] Configuration: mockmate/mockmate.json not found');
    }

    // 4. Fixtures directory check
    final fixturesDir = Directory(p.join('mockmate', 'fixtures'));
    if (await fixturesDir.exists()) {
      stdout.writeln('[OK] Fixtures: mockmate/fixtures/ present');
    } else {
      stdout.writeln(
          '[INFO] Fixtures: mockmate/fixtures/ directory not created yet');
    }

    // 5. Write permissions check
    try {
      final testFile = File('.mockmate_doctor_check');
      await testFile.writeAsString('ok');
      await testFile.delete();
      stdout.writeln('[OK] File system: write permissions confirmed');
    } catch (e) {
      stdout.writeln('[ERROR] File system: unable to write to workspace ($e)');
      hasErrors = true;
    }

    stdout.writeln();
    if (hasErrors) {
      stderr.writeln('Doctor found issues that need your attention.');
      return 1;
    }

    stdout.writeln('Doctor check completed: No blocking issues detected.');
    return 0;
  }
}
