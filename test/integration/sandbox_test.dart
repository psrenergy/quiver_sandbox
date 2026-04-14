@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  late String fixturesDir;
  late String tempOutputDir;
  late String tempDbDir;
  late QuiverSandbox sandbox;

  setUpAll(() {
    final result = Process.runSync('deno', ['--version'],
        runInShell: Platform.isWindows);
    if (result.exitCode != 0) {
      throw StateError('Deno is not installed or not on PATH');
    }
  });

  setUp(() {
    fixturesDir = p.normalize(p.absolute(p.join('test', 'fixtures')));
    tempOutputDir =
        Directory.systemTemp.createTempSync('quiver_sandbox_out_').path;
    tempDbDir =
        Directory.systemTemp.createTempSync('quiver_sandbox_db_').path;
    sandbox = QuiverSandbox();
  });

  tearDown(() {
    for (final path in [tempOutputDir, tempDbDir]) {
      final dir = Directory(path);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    }
  });

  String allowed(String name) =>
      p.normalize(p.join(fixturesDir, 'allowed', name));
  String denied(String name) =>
      p.normalize(p.join(fixturesDir, 'denied', name));

  /// Runs a fixture and returns (exitCode, output).
  Future<(int, String)> run(
    String scriptPath, {
    List<String> args = const [],
    List<String> additionalReadPaths = const [],
    String? denoCacheDir,
  }) async {
    final output = StringBuffer();
    final exitCode = await sandbox.execute(
      scriptPath: scriptPath,
      databasePath: tempDbDir,
      outputDir: tempOutputDir,
      args: args,
      additionalReadPaths: additionalReadPaths,
      denoCacheDir: denoCacheDir,
      writeInTerminal: output.write,
    );
    return (exitCode, output.toString());
  }

  group('Allowed operations', () {
    for (final fixture in [
      'hello.ts',
      'write_file.ts',
      'write_to_db_allowed.ts',
      'sys_info.ts',
      'empty_script.ts',
      'generate_html.ts',
      'generate_json.ts',
    ]) {
      test(fixture, () async {
        final (code, _) = await run(allowed(fixture),
            args: [tempOutputDir, tempDbDir]);
        expect(code, 0);
      });
    }

    test('QuiverDB open/close', () async {
      final migrationsDir =
          p.normalize(p.absolute(p.join('test', 'data', 'migrations')));
      final (code, out) = await run(
        allowed('quiverdb_open_close.ts'),
        args: [tempDbDir, migrationsDir],
        additionalReadPaths: [migrationsDir],
      );
      expect(code, 0, reason: out);
    });
  }, timeout: Timeout(Duration(minutes: 2)));

  group('Denied operations', () {
    for (final fixture in [
      'read_denied.ts',
      'run_denied.ts',
      'ffi_outside_db.ts',
      'net_denied.ts',
      'env_read.ts',
      'write_to_script_dir.ts',
      'write_to_system_dir.ts',
    ]) {
      test(fixture, () async {
        final (code, out) = await run(denied(fixture));
        expect(code, isNot(0));
        expect(out, contains('NotCapable'));
      });
    }

    test('third-party FFI blocked without cache in FFI scope', () async {
      final denoInfo = Process.runSync('deno', ['info', '--json'],
          runInShell: Platform.isWindows);
      final realDenoDir = RegExp(r'"denoDir"\s*:\s*"([^"]+)"')
          .firstMatch(denoInfo.stdout as String)
          ?.group(1)
          ?.replaceAll(r'\\', '/');
      expect(realDenoDir, isNotNull,
          reason: 'Could not detect Deno cache dir');

      final (code, out) = await run(
        denied('ffi_thirdparty_blocked.ts'),
        additionalReadPaths: [realDenoDir!],
        denoCacheDir: '/fake/deno/cache',
      );
      expect(code, isNot(0));
      expect(out, contains('NotCapable'));
    });

    test('syntax error', () async {
      final (code, out) = await run(denied('syntax_error.ts'));
      expect(code, isNot(0));
      expect(out, contains('error'));
    });

    test('runtime error', () async {
      final (code, out) = await run(denied('runtime_error.ts'));
      expect(code, isNot(0));
      expect(out, contains('intentional runtime error'));
    });

    test('Excel blocked by --deny-env', () async {
      final (code, out) =
          await run(allowed('generate_excel.ts'), args: [tempOutputDir]);
      expect(code, isNot(0));
      expect(out, contains('NotCapable'));
    });
  }, timeout: Timeout(Duration(minutes: 2)));
}
