@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

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
    tmp = Directory.systemTemp.createTempSync('runner_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('emits ProcessStarted/ProcessExited and streams output', () async {
    final script = File(p.join(tmp.path, 'hello.ts'))
      ..writeAsStringSync('console.log("hi");');
    final events = <SandboxEvent>[];
    final output = StringBuffer();

    final result = await QuiverSandbox().execute(
      SandboxRequest(
        scriptPath: script.path,
        workingDirectory: tmp.path,
        migrationsPath: tmp.path,
        onOutput: output.write,
        onEvent: events.add,
      ),
    );

    expect(result.exitCode, 0, reason: output.toString());
    expect(result.reason, TerminationReason.completed);
    expect(output.toString(), contains('hi'));
    expect(events.whereType<ProcessStartedEvent>(), hasLength(1));
    expect(events.whereType<ProcessExitedEvent>(), hasLength(1));
    expect(events.whereType<OutputChunkEvent>(), isNotEmpty);
  }, timeout: const Timeout(Duration(seconds: 30)));

  // Note: a "startFailure" assertion (missing executable) is platform-flaky
  // because on Windows we run Deno through a shell wrapper, which converts
  // "command not found" into a shell-level non-zero exit rather than a
  // ProcessException. The startFailure codepath is exercised when the
  // wrapper itself fails to launch (rare in tests).

  test('parses PermissionViolationEvent from stderr', () async {
    final script = File(p.join(tmp.path, 'deny.ts'))
      ..writeAsStringSync('await fetch("https://example.com");');
    final events = <SandboxEvent>[];

    final result = await QuiverSandbox().execute(
      SandboxRequest(
        scriptPath: script.path,
        workingDirectory: tmp.path,
        migrationsPath: tmp.path,
        onEvent: events.add,
      ),
    );

    expect(result.exitCode, isNot(0));
    final violations = events.whereType<PermissionViolationEvent>().toList();
    expect(violations, isNotEmpty);
    expect(violations.first.capability, equals('net'));
  }, timeout: const Timeout(Duration(seconds: 30)));
}
