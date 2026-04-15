import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

/// Discovers all `.ts` fixtures in [folder] (relative to `test/fixtures/`)
/// and generates a test for each one.
///
/// [expectExitCode] is the matcher applied to the process exit code.
void sandboxFixtureTests({
  required String folder,
  required Matcher expectExitCode,
}) {
  late String fixturesDir;
  late String databasePath;
  late String migrationsPath;
  late QuiverSandbox sandbox;

  setUpAll(() {
    final result = Process.runSync('deno', [
      '--version',
    ], runInShell: Platform.isWindows);
    if (result.exitCode != 0) {
      throw StateError('Deno is not installed or not on PATH');
    }
  });

  setUp(() {
    fixturesDir = p.normalize(
      p.absolute(p.join('test', 'fixtures', folder)),
    );
    databasePath =
        Directory.systemTemp.createTempSync('quiver_sandbox_db_').path;
    migrationsPath = p.normalize(
      p.absolute(p.join('test', 'data', 'migrations')),
    );
    sandbox = QuiverSandbox();
  });

  tearDown(() {
    final dir = Directory(databasePath);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  final fixtures = Directory(p.normalize(
    p.absolute(p.join('test', 'fixtures', folder)),
  )).listSync().whereType<File>().where((f) => f.path.endsWith('.ts'));

  for (final fixture in fixtures) {
    final name = p.basename(fixture.path);
    test(name, () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: p.normalize(p.join(fixturesDir, name)),
        databasePath: databasePath,
        migrationsPath: migrationsPath,
        writeInTerminal: output.write,
      );
      expect(exitCode, expectExitCode, reason: output.toString());
    });
  }
}
