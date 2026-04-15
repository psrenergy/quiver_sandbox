@TestOn('vm')
library;

import 'package:test/test.dart';

import 'sandbox_harness.dart';

void main() {
  sandboxFixtureTests(folder: 'allowed', expectExitCode: equals(0));
}
