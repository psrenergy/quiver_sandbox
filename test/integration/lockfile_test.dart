@TestOn('vm')
library;

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

import 'sandbox_harness.dart';

/// Verifies that the fixed policy rejects any import not pinned in the
/// package's bundled lockfile. `untrusted_import.ts` imports `npm:left-pad`,
/// which is intentionally absent from `lockfile/deno.lock`.
void main() {
  final env = registerSandboxEnv('lockfile');

  test('untrusted import fails under the fixed frozen policy', () async {
    final scriptPath = p.normalize(
      p.absolute(p.join('test', 'fixtures', 'lockfile', 'untrusted_import.ts')),
    );
    final output = StringBuffer();
    final result = await QuiverSandbox().execute(
      SandboxRequest(
        scriptPath: scriptPath,
        workingDirectory: env.workingDirectory,
        migrationsPath: env.migrationsPath,
        onOutput: output.write,
      ),
    );

    expect(result.exitCode, isNot(0), reason: output.toString());
  });
}
