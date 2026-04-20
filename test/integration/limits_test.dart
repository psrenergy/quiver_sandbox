@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  late String workingDirectory;
  late String migrationsPath;
  late QuiverSandbox sandbox;

  setUpAll(() {
    final probe = Process.runSync(
      'deno',
      ['--version'],
      runInShell: Platform.isWindows,
    );
    if (probe.exitCode != 0) {
      throw StateError('Deno is not installed or not on PATH');
    }
  });

  setUp(() {
    workingDirectory = Directory.systemTemp
        .createTempSync('qsb_limits_')
        .path;
    migrationsPath = p.normalize(
      p.absolute(p.join('test', 'data', 'migrations')),
    );
    sandbox = QuiverSandbox();
  });

  tearDown(() {
    final dir = Directory(workingDirectory);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('infinite_loop.ts → TerminationReason.timedOut', () async {
    final events = <SandboxEvent>[];
    final result = await sandbox.execute(
      SandboxRequest(
        scriptPath: p.normalize(
          p.absolute(p.join('test', 'fixtures', 'limits', 'infinite_loop.ts')),
        ),
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
        timeout: const Duration(seconds: 2),
        onEvent: events.add,
      ),
    );

    expect(result.reason, TerminationReason.timedOut);
    expect(events.whereType<TimeoutEvent>(), hasLength(1));
    expect(
      result.elapsed.inMilliseconds,
      greaterThanOrEqualTo(1800),
      reason: 'Should have run at least the timeout duration.',
    );
  }, timeout: const Timeout(Duration(seconds: 20)));

  test('output_flood.ts → TerminationReason.outputCapExceeded', () async {
    final events = <SandboxEvent>[];
    final result = await sandbox.execute(
      SandboxRequest(
        scriptPath: p.normalize(
          p.absolute(p.join('test', 'fixtures', 'limits', 'output_flood.ts')),
        ),
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
        timeout: const Duration(seconds: 30),
        maxOutputBytes: 200_000, // ~200 KB — hits cap fast.
        onEvent: events.add,
      ),
    );

    expect(result.reason, TerminationReason.outputCapExceeded);
    expect(events.whereType<OutputCapEvent>(), hasLength(1));
    expect(
      result.outputBytesEmitted,
      greaterThan(200_000),
      reason: 'Should have emitted more than the cap before killing.',
    );
  }, timeout: const Timeout(Duration(seconds: 30)));
}
