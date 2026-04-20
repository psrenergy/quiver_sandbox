@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

/// Verifies that the fixed policy rejects any import not pinned in the
/// package's bundled lockfile. `untrusted_import.ts` imports `npm:left-pad`,
/// which is intentionally absent from `lockfile/deno.lock`.
void main() {
  late String workingDirectory;
  late String migrationsPath;
  late String scriptPath;

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
  });

  tearDown(() {
    final dir = Directory(workingDirectory);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('untrusted import fails under the fixed frozen policy', () async {
    final output = StringBuffer();
    final result = await QuiverSandbox().execute(
      SandboxRequest(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
        onOutput: output.write,
      ),
    );

    expect(result.exitCode, isNot(0), reason: output.toString());
  });
}
