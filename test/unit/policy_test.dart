@TestOn('vm')
library;

import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

void main() {
  group('SandboxPolicy.buildFlags', () {
    const scriptPath = '/abs/script/foo.ts';
    const workingDirectory = '/abs/wd';
    const migrationsPath = '/abs/migrations';
    const denoCacheDir = '/abs/cache';

    test('default policy emits secure-by-default flags', () {
      final flags = const SandboxPolicy().buildFlags(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
        denoCacheDir: denoCacheDir,
      );

      expect(
        flags,
        containsAll(<String>[
          '--allow-write=/abs/wd',
          '--allow-net=jsr.io,registry.npmjs.org,esm.sh',
          '--allow-ffi',
          '--deny-run',
          '--no-lock',
        ]),
      );
      expect(
        flags.firstWhere((f) => f.startsWith('--allow-read=')),
        equals('--allow-read=/abs/wd,/abs/script,/abs/migrations,/abs/cache'),
      );
      expect(
        flags.firstWhere((f) => f.startsWith('--allow-env=')),
        contains('MIGRATIONS_DIR'),
      );
      expect(flags, isNot(contains('--allow-sys')));
      expect(flags, isNot(contains('--frozen')));
    });

    test('omits denoCacheDir from read when null', () {
      final flags = const SandboxPolicy().buildFlags(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
      );
      expect(
        flags.firstWhere((f) => f.startsWith('--allow-read=')),
        equals('--allow-read=/abs/wd,/abs/script,/abs/migrations'),
      );
    });

    test('lockfile with allowArbitraryPackages=false yields --lock and --frozen', () {
      final flags = const SandboxPolicy(lockfilePath: '/abs/deno.lock')
          .buildFlags(
            scriptPath: scriptPath,
            workingDirectory: workingDirectory,
            migrationsPath: migrationsPath,
          );
      expect(flags, contains('--lock=/abs/deno.lock'));
      expect(flags, contains('--frozen'));
      expect(flags, isNot(contains('--no-lock')));
    });

    test('allowArbitraryPackages=true falls back to --no-lock', () {
      final flags = const SandboxPolicy(
        lockfilePath: '/abs/deno.lock',
        allowArbitraryPackages: true,
      ).buildFlags(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
      );
      expect(flags, contains('--no-lock'));
      expect(flags, isNot(contains('--frozen')));
      expect(flags, isNot(contains('--lock=/abs/deno.lock')));
    });

    test('allowSys adds --allow-sys', () {
      final flags = const SandboxPolicy(allowSys: true).buildFlags(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
      );
      expect(flags, contains('--allow-sys'));
    });

    test('custom allowedHosts and allowedEnv propagate', () {
      final flags = const SandboxPolicy(
        allowedHosts: {'example.com'},
        allowedEnv: {'CUSTOM_VAR'},
      ).buildFlags(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
      );
      expect(flags, contains('--allow-net=example.com'));
      expect(flags, contains('--allow-env=CUSTOM_VAR'));
    });
  });

  group('SandboxRequest', () {
    test('rejects relative scriptPath', () {
      expect(
        () => SandboxRequest(
          scriptPath: 'rel/path.ts',
          workingDirectory: '/abs/wd',
          migrationsPath: '/abs/migrations',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects zero maxOutputBytes', () {
      expect(
        () => SandboxRequest(
          scriptPath: '/abs/script.ts',
          workingDirectory: '/abs/wd',
          migrationsPath: '/abs/migrations',
          maxOutputBytes: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
