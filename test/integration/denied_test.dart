@TestOn('vm')
library;

import 'package:test/test.dart';

import 'sandbox_harness.dart';

void main() {
  sandboxFixtureTests(folder: 'denied', expectExitCode: isNot(0));
}
