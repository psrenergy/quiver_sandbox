import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  group('QuiverSandbox', () {
    test('uses "deno" as default executable', () {
      final sandbox = QuiverSandbox();
      expect(sandbox.denoExecutable, equals('deno'));
    });

    test('accepts a custom executable path', () {
      final sandbox = QuiverSandbox(denoExecutable: '/usr/local/bin/deno');
      expect(sandbox.denoExecutable, equals('/usr/local/bin/deno'));
    });
  });
}
