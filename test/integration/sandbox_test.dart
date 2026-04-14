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

  String allowed(String name) =>
      p.normalize(p.join(fixturesDir, 'allowed', name));

  String denied(String name) =>
      p.normalize(p.join(fixturesDir, 'denied', name));

  group('Allowed operations', () {
    test('script receives positional args', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: allowed('hello.ts'),
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
        scriptPath: allowed('write_file.ts'),
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

    test('script CAN access sys info', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: allowed('sys_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, equals(0));
      expect(output.toString(), contains('hostname:'));
    });

    test('script CAN write to databasePath', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: allowed('write_to_db_allowed.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempDbDir],
        writeInTerminal: output.write,
      );
      expect(exitCode, equals(0));
      expect(output.toString(), contains('wrote to databasePath'));
      final file = File(p.join(tempDbDir, 'test_write.txt'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), equals('db write ok'));
    });

    test('empty script exits zero', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: allowed('empty_script.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, equals(0));
    });

    test('script can open and close QuiverDB database', () async {
      final migrationsDir = p.normalize(
        p.absolute(p.join('test', 'data', 'migrations')),
      );

      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: allowed('quiverdb_open_close.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempDbDir, migrationsDir],
        additionalReadPaths: [migrationsDir],
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

    test('script generates HTML file in outputDir', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: allowed('generate_html.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempOutputDir],
        writeInTerminal: output.write,
      );
      expect(exitCode, equals(0));
      expect(output.toString(), contains('html generated'));
      final file = File(p.join(tempOutputDir, 'report.html'));
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('QuiverSandbox Report'));
    });

    test('script generates JSON file in outputDir', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: allowed('generate_json.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempOutputDir],
        writeInTerminal: output.write,
      );
      expect(exitCode, equals(0));
      expect(output.toString(), contains('json generated'));
      final file = File(p.join(tempOutputDir, 'data.json'));
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('"status": "ok"'));
    });
  }, timeout: Timeout(Duration(minutes: 2)));

  group('Denied operations', () {
    test('script CANNOT read outside allowed dirs', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: denied('read_denied.ts'),
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
        scriptPath: denied('run_denied.ts'),
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
        scriptPath: denied('ffi_outside_db.ts'),
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
        scriptPath: denied('net_denied.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

    test('script CANNOT read environment variables', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: denied('env_read.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

    test('script CANNOT write to its own directory', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: denied('write_to_script_dir.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

    test('script CANNOT write to system directory', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: denied('write_to_system_dir.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

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
        scriptPath: denied('ffi_thirdparty_blocked.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        additionalReadPaths: [realDenoDir!],
        denoCacheDir: '/fake/deno/cache',
        writeInTerminal: output.write,
      );

      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });

    test('syntax error exits non-zero', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: denied('syntax_error.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('error'));
    });

    test('runtime error exits non-zero', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: denied('runtime_error.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('intentional runtime error'));
    });

    test('Excel generation blocked by --deny-env', () async {
      final output = StringBuffer();
      final exitCode = await sandbox.execute(
        scriptPath: allowed('generate_excel.ts'),
        databasePath: tempDbDir,
        outputDir: tempOutputDir,
        args: [tempOutputDir],
        writeInTerminal: output.write,
      );
      expect(exitCode, isNot(0));
      expect(output.toString(), contains('NotCapable'));
    });
  }, timeout: Timeout(Duration(minutes: 2)));
}
