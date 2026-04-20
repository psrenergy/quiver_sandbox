@TestOn('vm')
library;

import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

import 'sandbox_harness.dart';

void main() {
  sandboxFixtureTests(
    folder: 'permit',
    policyBuilder: () async => SandboxPolicy(
      lockfilePath: await QuiverSandbox.resolveBundledLockfilePath(),
    ),
    verify: (result, output, events) {
      expect(result.exitCode, 0, reason: output.toString());
      expect(result.reason, TerminationReason.completed);
    },
  );
}
