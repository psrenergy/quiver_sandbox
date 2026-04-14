import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  const builder = PermissionBuilder();

  SandboxConfig makeConfig({
    String scriptPath = '/scripts/report.ts',
    String databasePath = '/data/mydb',
    String outputDir = '/tmp/output',
    List<String> args = const [],
    List<String> allowedNetHosts = const ['registry.npmjs.org', 'esm.sh'],
    bool allowSys = false,
  }) {
    return SandboxConfig(
      scriptPath: scriptPath,
      databasePath: databasePath,
      outputDir: outputDir,
      args: args,
      allowedNetHosts: allowedNetHosts,
      allowSys: allowSys,
    );
  }

  group('PermissionBuilder', () {
    test('includes --allow-read scoped to databasePath and script dir', () {
      final flags = builder.buildFlags(makeConfig());
      expect(flags, contains('--allow-read=/data/mydb,/scripts'));
    });

    test('includes --allow-write scoped to outputDir only', () {
      final flags = builder.buildFlags(makeConfig());
      expect(flags, contains('--allow-write=/tmp/output'));
    });

    test('includes --allow-net scoped to default npm registries', () {
      final flags = builder.buildFlags(makeConfig());
      expect(flags, contains('--allow-net=registry.npmjs.org,esm.sh'));
    });

    test('includes --allow-ffi scoped to databasePath', () {
      final flags = builder.buildFlags(makeConfig());
      expect(flags, contains('--allow-ffi=/data/mydb'));
    });

    test('includes --deny-run always', () {
      final flags = builder.buildFlags(makeConfig());
      expect(flags, contains('--deny-run'));
    });

    test('includes --deny-sys by default', () {
      final flags = builder.buildFlags(makeConfig());
      expect(flags, contains('--deny-sys'));
      expect(flags, isNot(contains('--allow-sys')));
    });

    test('includes --allow-sys when allowSys is true', () {
      final flags = builder.buildFlags(makeConfig(allowSys: true));
      expect(flags, contains('--allow-sys'));
      expect(flags, isNot(contains('--deny-sys')));
    });

    test('uses custom allowedNetHosts', () {
      final flags = builder.buildFlags(
        makeConfig(allowedNetHosts: ['cdn.example.com']),
      );
      expect(flags, contains('--allow-net=cdn.example.com'));
    });

    test('throws ArgumentError for relative scriptPath', () {
      expect(
        () => builder.buildFlags(makeConfig(scriptPath: 'relative/script.ts')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for relative databasePath', () {
      expect(
        () => builder.buildFlags(makeConfig(databasePath: 'relative/db')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for relative outputDir', () {
      expect(
        () => builder.buildFlags(makeConfig(outputDir: 'relative/output')),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
