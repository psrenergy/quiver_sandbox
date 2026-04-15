@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  late String fixturesDir;
  late String outputDir;
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
    fixturesDir = p.normalize(p.absolute(p.join('test', 'fixtures')));
    outputDir = Directory.systemTemp
        .createTempSync('quiver_sandbox_out_')
        .path;
    databasePath = Directory.systemTemp.createTempSync('quiver_sandbox_db_').path;
    migrationsPath = p.normalize(
      p.absolute(p.join('test', 'data', 'migrations')),
    );
    sandbox = QuiverSandbox();
  });

  tearDown(() {
    for (final path in [outputDir, databasePath]) {
      final dir = Directory(path);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  String allowed(String name) =>
      p.normalize(p.join(fixturesDir, 'allowed', name));
  String denied(String name) =>
      p.normalize(p.join(fixturesDir, 'denied', name));

  Future<(int, String)> run(
    String scriptPath, {
    List<String> args = const [],
  }) async {
    final output = StringBuffer();
    final exitCode = await sandbox.execute(
      scriptPath: scriptPath,
      databasePath: databasePath,
      outputDir: outputDir,
      args: args,
      migrationsPath: migrationsPath,
      writeInTerminal: output.write,
    );
    return (exitCode, output.toString());
  }

  for (final fixture in [
    'hello.ts',
    'write_file.ts',
    'write_to_db_allowed.ts',
    'sys_info.ts',
    'empty_script.ts',
    'generate_html.ts',
    'generate_json.ts',
    'quiverdb_open_close.ts',
  ]) {
    test('allowed: $fixture', () async {
      final (code, _) = await run(
        allowed(fixture),
        args: [outputDir, tempDbDir],
      );
      expect(code, 0);
    });
  }

  for (final fixture in [
    'read_denied.ts',
    'run_denied.ts',
    'ffi_outside_db.ts',
    'net_denied.ts',
    'env_read.ts',
    'write_to_script_dir.ts',
    'write_to_system_dir.ts',
    'runtime_error.ts',
    'syntax_error.ts',
    'ffi_thirdparty_blocked.ts',
  ]) {
    test('denied: $fixture', () async {
      final (code, out) = await run(denied(fixture));
      expect(code, isNot(0));
    });
  }
}
