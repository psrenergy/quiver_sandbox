@TestOn('vm')
library;

import 'package:test/test.dart';

import 'sandbox_harness.dart';

void main() {
  // Each forbid fixture exits non-zero for its own independent reason —
  // permission violation, runtime error, syntax error, etc.
  sandboxFixtureTests(
    folder: 'forbid',
    verify: (result, output, events) {
      expect(result.exitCode, isNot(0), reason: output.toString());
    },
  );
}
