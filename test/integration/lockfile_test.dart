@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  late String workingDirectory;
  late String migrationsPath;
  late String scriptPath;
  late String lockfile;

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
        .createTempSync('qsb_lockfile_')
        .path;
    migrationsPath = p.normalize(
      p.absolute(p.join('test', 'data', 'migrations')),
    );
    scriptPath = p.normalize(
      p.absolute(
        p.join('test', 'fixtures', 'lockfile', 'untrusted_import.ts'),
      ),
    );
    lockfile = p.normalize(
      p.absolute(p.join('test', 'data', 'deno.lock')),
    );
  });

  tearDown(() {
    final dir = Directory(workingDirectory);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('untrusted import fails under lockfile + --frozen', () async {
    final output = StringBuffer();
    final result = await QuiverSandbox().execute(
      SandboxRequest(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
        policy: SandboxPolicy(lockfilePath: lockfile),
        onOutput: output.write,
      ),
    );

    expect(result.exitCode, isNot(0), reason: output.toString());
    // Deno reports this as either a lockfile miss or a module resolution error.
    // Either way, the import fails before user code runs.
  });

  test('untrusted import succeeds when allowArbitraryPackages=true', () async {
    final output = StringBuffer();
    final result = await QuiverSandbox().execute(
      SandboxRequest(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
        policy: const SandboxPolicy(allowArbitraryPackages: true),
        onOutput: output.write,
      ),
    );

    expect(result.exitCode, 0, reason: output.toString());
  }, timeout: const Timeout(Duration(seconds: 60)));
}
