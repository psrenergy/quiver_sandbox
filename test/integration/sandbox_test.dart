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

  SandboxConfig configFor(
    String fixtureName, {
    List<String> args = const [],
    bool allowSys = false,
  }) {
    return SandboxConfig(
      scriptPath: p.normalize(p.join(fixturesDir, fixtureName)),
      databasePath: tempDbDir,
      outputDir: tempOutputDir,
      args: args,
      allowSys: allowSys,
    );
  }

  group('Allowed operations', () {
    test('script receives positional args', () async {
      final result = await sandbox.execute(
        configFor('hello.ts', args: ['arg1', 'arg2', 'arg3']),
      );
      expect(result.success, isTrue);
      expect(result.stdout.trim(), equals('["arg1","arg2","arg3"]'));
    });

    test('script can write to outputDir', () async {
      final result = await sandbox.execute(
        configFor('write_file.ts', args: [tempOutputDir]),
      );
      expect(result.success, isTrue);
      final outputFile = File(p.join(tempOutputDir, 'test_output.txt'));
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.readAsStringSync(), equals('hello from sandbox'));
    });
  });

  group('Denied operations', () {
    test('script CANNOT read outside allowed dirs', () async {
      final result = await sandbox.execute(configFor('read_denied.ts'));
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });

    test('script CANNOT spawn subprocesses', () async {
      final result = await sandbox.execute(configFor('run_denied.ts'));
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });

    test('script CANNOT load FFI outside databasePath', () async {
      final result = await sandbox.execute(configFor('ffi_outside_db.ts'));
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });

    test('script CANNOT fetch non-allowed hosts', () async {
      final result = await sandbox.execute(configFor('net_denied.ts'));
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });
  });

  group('--deny-sys toggle', () {
    test('script CANNOT access sys info with allowSys=false', () async {
      final result = await sandbox.execute(
        configFor('sys_denied.ts', allowSys: false),
      );
      expect(result.success, isFalse);
      expect(result.stderr, contains('NotCapable'));
    });

    test('script CAN access sys info with allowSys=true', () async {
      final result = await sandbox.execute(
        configFor('sys_denied.ts', allowSys: true),
      );
      expect(result.success, isTrue);
      expect(result.stdout, contains('hostname:'));
    });
  });
}
