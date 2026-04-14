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

  group('DenoResult', () {
    test('success is true when exitCode is 0', () {
      const result = DenoResult(stdout: 'ok', stderr: '', exitCode: 0);
      expect(result.success, isTrue);
    });

    test('success is false when exitCode is non-zero', () {
      const result = DenoResult(stdout: '', stderr: 'err', exitCode: 1);
      expect(result.success, isFalse);
    });
  });
}
