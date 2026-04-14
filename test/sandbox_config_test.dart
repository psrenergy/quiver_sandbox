import 'package:quiver_sandbox/src/sandbox_config.dart';
import 'package:test/test.dart';

void main() {
  group('SandboxConfig', () {
    test('stores required fields', () {
      final config = SandboxConfig(
        scriptPath: '/scripts/report.ts',
        databasePath: '/data/mydb',
        outputDir: '/tmp/output',
      );
      expect(config.scriptPath, equals('/scripts/report.ts'));
      expect(config.databasePath, equals('/data/mydb'));
      expect(config.outputDir, equals('/tmp/output'));
    });

    test('args defaults to empty list', () {
      final config = SandboxConfig(
        scriptPath: '/scripts/report.ts',
        databasePath: '/data/mydb',
        outputDir: '/tmp/output',
      );
      expect(config.args, isEmpty);
    });

    test('allowedNetHosts defaults to npm registries', () {
      final config = SandboxConfig(
        scriptPath: '/scripts/report.ts',
        databasePath: '/data/mydb',
        outputDir: '/tmp/output',
      );
      expect(
        config.allowedNetHosts,
        equals(['registry.npmjs.org', 'esm.sh']),
      );
    });

    test('allowSys defaults to false', () {
      final config = SandboxConfig(
        scriptPath: '/scripts/report.ts',
        databasePath: '/data/mydb',
        outputDir: '/tmp/output',
      );
      expect(config.allowSys, isFalse);
    });

    test('timeout defaults to null', () {
      final config = SandboxConfig(
        scriptPath: '/scripts/report.ts',
        databasePath: '/data/mydb',
        outputDir: '/tmp/output',
      );
      expect(config.timeout, isNull);
    });

    test('accepts custom values for all optional fields', () {
      final config = SandboxConfig(
        scriptPath: '/scripts/report.ts',
        databasePath: '/data/mydb',
        outputDir: '/tmp/output',
        args: ['--month', '2026-03'],
        allowedNetHosts: ['cdn.example.com'],
        allowSys: true,
        timeout: Duration(seconds: 30),
      );
      expect(config.args, equals(['--month', '2026-03']));
      expect(config.allowedNetHosts, equals(['cdn.example.com']));
      expect(config.allowSys, isTrue);
      expect(config.timeout, equals(Duration(seconds: 30)));
    });
  });
}
