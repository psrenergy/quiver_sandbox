@TestOn('vm')
library;

import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:quiver_sandbox/src/policy.dart';
import 'package:test/test.dart';

void main() {
  group('SandboxPolicy.buildFlags', () {
    const scriptPath = '/abs/script/foo.ts';
    const workingDirectory = '/abs/wd';
    const migrationsPath = '/abs/migrations';
    const denoCacheDir = '/abs/cache';
    const lockfile = '/abs/deno.lock';

    test('emits the fixed secure-by-default flag set', () {
      final flags = const SandboxPolicy(lockfilePath: lockfile).buildFlags(
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
          '--lock=$lockfile',
          '--frozen',
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
      expect(flags, isNot(contains('--no-lock')));
    });

    test('omits denoCacheDir from read when null', () {
      final flags = const SandboxPolicy(lockfilePath: lockfile).buildFlags(
        scriptPath: scriptPath,
        workingDirectory: workingDirectory,
        migrationsPath: migrationsPath,
      );
      expect(
        flags.firstWhere((f) => f.startsWith('--allow-read=')),
        equals('--allow-read=/abs/wd,/abs/script,/abs/migrations'),
      );
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
