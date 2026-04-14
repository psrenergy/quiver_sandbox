@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

/// Integration tests that require Deno to be installed.
void main() {
  late String fixturesDir;
  late String tempOutputDir;
  late String tempDbDir;
  late QuiverSandbox sandbox;

  setUpAll(() {
    // Verify Deno is available.
    final result = Process.runSync(
      'deno',
      ['--version'],
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) {
      throw StateError('Deno is not installed or not on PATH');
    }
  });

  setUp(() {
    fixturesDir = p.normalize(
      p.absolute(p.join('test', 'fixtures')),
    );
    tempOutputDir = Directory.systemTemp
        .createTempSync('quiver_sandbox_out_')
        .path;
    tempDbDir = Directory.systemTemp
        .createTempSync('quiver_sandbox_db_')
        .path;
    sandbox = QuiverSandbox();
  });

  tearDown(() {
    // Clean up temp dirs.
    final outDir = Directory(tempOutputDir);
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
    final dbDir = Directory(tempDbDir);
    if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  });

  String fixturePath(String name) =>
      p.normalize(p.join(fixturesDir, name));

  group('Allowed operations', () {
    test('script receives positional args', () async {
      final result = await sandbox.execute(
        scriptPath: fixturePath('hello.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: ['arg1', 'arg2', 'arg3'],
      );
      expect(result.success, isTrue);
      expect(result.stdout.trim(), equals('["arg1","arg2","arg3"]'));
    });

    test('script can write to outputDir', () async {
      final result = await sandbox.execute(
        scriptPath: fixturePath('write_file.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempOutputDir],
      );
      expect(result.success, isTrue);
      final outputFile = File(p.join(tempOutputDir, 'test_output.txt'));
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync(), equals('hello from sandbox'));
    });
  });

  group('Denied operations', () {
    test('script CANNOT read outside allowed dirs', () async {
      final result = await sandbox.execute(
        scriptPath: fixturePath('read_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
      );
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });

    test('script CANNOT spawn subprocesses', () async {
      final result = await sandbox.execute(
        scriptPath: fixturePath('run_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
      );
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });

    test('script CANNOT load FFI outside databasePath', () async {
      final result = await sandbox.execute(
        scriptPath: fixturePath('ffi_outside_db.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
      );
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });

    test('script CANNOT fetch non-allowed hosts', () async {
      final result = await sandbox.execute(
        scriptPath: fixturePath('net_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
      );
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });
  });

  group('--deny-sys toggle', () {
    test('script CANNOT access sys info with allowSys=false', () async {
      final result = await sandbox.execute(
        scriptPath: fixturePath('sys_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        allowSys: false,
      );
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });

    test('script CAN access sys info with allowSys=true', () async {
      final result = await sandbox.execute(
        scriptPath: fixturePath('sys_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        allowSys: true,
      );
      expect(result.success, isTrue);
      expect(result.stdout, contains('hostname:'));
    });
  });

  group('QuiverDB operations', () {
    test('script can open and close QuiverDB database', () async {
      final migrationsDir = p.normalize(
        p.absolute(p.join('test', 'data', 'migrations')),
      );

      final result = await sandbox.execute(
        scriptPath: fixturePath('quiverdb_open_close.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempDbDir, migrationsDir],
        additionalReadPaths: [migrationsDir],
        allowSys: true,
      );

      // Print stderr for debugging if it fails.
      if (!result.success) {
        // ignore: avoid_print
        print('stderr: ${result.stderr}');
      }

      expect(result.success, isTrue, reason: result.stderr);
      expect(result.stdout, contains('database opened successfully'));
      expect(result.stdout, contains('database closed successfully'));
    });
  }, timeout: Timeout(Duration(minutes: 2)));

  group('Third-party FFI restriction', () {
    test('third-party FFI package is blocked without Deno cache in FFI scope',
        () async {
      // Resolve the real Deno cache dir so we can grant read access (for npm
      // import resolution) while keeping it OUT of the FFI allow list.
      final denoInfo = Process.runSync(
        'deno',
        ['info', '--json'],
        runInShell: Platform.isWindows,
      );
      final realDenoDir =
          (denoInfo.stdout as String).contains('denoDir')
              ? RegExp(r'"denoDir"\s*:\s*"([^"]+)"')
                    .firstMatch(denoInfo.stdout as String)
                    ?.group(1)
                    ?.replaceAll(r'\\', '/')
              : null;

      expect(realDenoDir, isNotNull, reason: 'Could not detect Deno cache dir');

      // Grant --allow-read to the real cache (so npm: imports resolve),
      // but set denoCacheDir to a fake path so --allow-ffi excludes it.
      final result = await sandbox.execute(
        scriptPath: fixturePath('ffi_thirdparty_blocked.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        additionalReadPaths: [realDenoDir!],
        denoCacheDir: '/fake/deno/cache',
        allowSys: true,
      );

      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });
  }, timeout: Timeout(Duration(minutes: 2)));
}
