@TestOn('vm')
library;

import 'package:test/test.dart';

import 'sandbox_harness.dart';

void main() {
  // Default policy (no lockfile). Each forbid fixture is expected to exit
  // non-zero for its own independent reason — permission violation, runtime
  // error, syntax error, etc.
  sandboxFixtureTests(
    folder: 'forbid',
    verify: (result, output, events) {
      expect(result.exitCode, isNot(0), reason: output.toString());
    },
  );
}
