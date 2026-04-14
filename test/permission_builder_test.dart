import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  const builder = PermissionBuilder();

  List<String> buildDefault({
    String scriptPath = '/scripts/report.ts',
    String databasePath = '/data/mydb',
    String outputDir = '/tmp/output',
    List<String> additionalReadPaths = const [],
    String? denoCacheDir,
  }) {
    return builder.buildFlags(
      scriptPath: scriptPath,
      databasePath: databasePath,
      outputDir: outputDir,
      additionalReadPaths: additionalReadPaths,
      denoCacheDir: denoCacheDir,
    );
  }

  group('PermissionBuilder', () {
    test('includes --allow-read scoped to databasePath and script dir', () {
      final flags = buildDefault();
      expect(flags, contains('--allow-read=/data/mydb,/scripts'));
    });

    test('includes --allow-write scoped to databasePath and outputDir', () {
      final flags = buildDefault();
      expect(flags, contains('--allow-write=/data/mydb,/tmp/output'));
    });

    test('includes --allow-net scoped to npm registries', () {
      final flags = buildDefault();
      expect(flags, contains('--allow-net=registry.npmjs.org,esm.sh'));
    });

    test('includes --allow-ffi scoped to databasePath', () {
      final flags = buildDefault();
      expect(flags, contains('--allow-ffi=/data/mydb'));
    });

    test('includes --deny-run always', () {
      final flags = buildDefault();
      expect(flags, contains('--deny-run'));
    });

    test('includes --allow-env always', () {
      final flags = buildDefault();
      expect(flags, contains('--allow-env'));
    });

    test('includes --allow-sys always', () {
      final flags = buildDefault();
      expect(flags, contains('--allow-sys'));
    });

    test('includes additionalReadPaths in --allow-read', () {
      final flags = buildDefault(
        additionalReadPaths: ['/extra/data', '/extra/migrations'],
      );
      expect(
        flags,
        contains('--allow-read=/data/mydb,/scripts,/extra/data,/extra/migrations'),
      );
    });

    test('includes denoCacheDir in --allow-read and --allow-ffi', () {
      final flags = buildDefault(denoCacheDir: '/home/user/.deno');
      expect(flags, contains('--allow-read=/data/mydb,/scripts,/home/user/.deno'));
      expect(flags, contains('--allow-ffi=/data/mydb,/home/user/.deno'));
    });

    test('throws ArgumentError for relative scriptPath', () {
      expect(
        () => buildDefault(scriptPath: 'relative/script.ts'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for relative databasePath', () {
      expect(
        () => buildDefault(databasePath: 'relative/db'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for relative outputDir', () {
      expect(
        () => buildDefault(outputDir: 'relative/output'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for relative additionalReadPaths', () {
      expect(
        () => buildDefault(additionalReadPaths: ['relative/path']),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
