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
    final outDir = Directory(tempOutputDir);
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
    final dbDir = Directory(tempDbDir);
    if (dbDir.existsSync()) dbDir.deleteSync(recursive: true);
  });

  String fixturePath(String name) =>
      p.normalize(p.join(fixturesDir, name));

  group('Allowed operations', () {
    test('script receives positional args', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('hello.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: ['arg1', 'arg2', 'arg3'],
        writeInTerminal: output.write,
      );
      expect(exitCode, equals(0));
      expect(output.toString().trim(), equals('["arg1","arg2","arg3"]'));
    });

    test('script can write to outputDir', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('write_file.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempOutputDir],
        writeInTerminal: output.write,
      );
      expect(exitCode, equals(0));
      final outputFile = File(p.join(tempOutputDir, 'test_output.txt'));
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync(), equals('hello from sandbox'));
    });
  });

  group('Denied operations', () {
    test('script CANNOT read outside allowed dirs', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('read_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

    test('script CANNOT spawn subprocesses', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('run_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

    test('script CANNOT load FFI outside databasePath', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('ffi_outside_db.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

    test('script CANNOT fetch non-allowed hosts', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('net_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });
  });

  group('--deny-sys toggle', () {
    test('script CANNOT access sys info with allowSys=false', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('sys_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        allowSys: false,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

    test('script CAN access sys info with allowSys=true', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('sys_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        allowSys: true,
        writeInTerminal: output.write,
      );
      expect(exitCode, equals(0));
      expect(output.toString(), contains('hostname:'));
    });
  });

  group('QuiverDB operations', () {
    test('script can open and close QuiverDB database', () async {
      final migrationsDir = p.normalize(
        p.absolute(p.join('test', 'data', 'migrations')),
      );

      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('quiverdb_open_close.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempDbDir, migrationsDir],
        additionalReadPaths: [migrationsDir],
        allowSys: true,
        writeInTerminal: output.write,
      );

      if (exitCode != 0) {
        // ignore: avoid_print
        print('output: ${output.toString()}');
      }

      expect(exitCode, equals(0), reason: output.toString());
      expect(output.toString(), contains('database opened successfully'));
      expect(output.toString(), contains('database closed successfully'));
    });
  }, timeout: Timeout(Duration(minutes: 2)));

  group('Third-party FFI restriction', () {
    test('third-party FFI package is blocked without Deno cache in FFI scope',
        () async {
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

      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: fixturePath('ffi_thirdparty_blocked.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        additionalReadPaths: [realDenoDir!],
        denoCacheDir: '/fake/deno/cache',
        allowSys: true,
        writeInTerminal: output.write,
      );

      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });
  }, timeout: Timeout(Duration(minutes: 2)));
}
