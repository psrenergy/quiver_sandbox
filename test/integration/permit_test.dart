@TestOn('vm')
library;

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

import 'sandbox_harness.dart';

void main() {
  final lockfile = p.normalize(
    p.absolute(p.join('test', 'data', 'deno.lock')),
  );

  sandboxFixtureTests(
    folder: 'permit',
    policy: SandboxPolicy(lockfilePath: lockfile),
    verify: (result, output, events) {
      expect(result.exitCode, 0, reason: output.toString());
      expect(result.reason, TerminationReason.completed);
    },
  );
}
