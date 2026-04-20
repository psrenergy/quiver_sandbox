/// [SandboxPolicy] models the static part of a sandbox configuration —
/// what hosts, env vars, and packages the sandboxed code is allowed to touch.
///
/// Defaults are **secure-by-default**: minimum network reach, a curated env
/// allowlist covering Node-compat probes used by common npm packages, FFI
/// unscoped (a Deno 2.x limitation — see comment on [buildFlags]), `--allow-sys`
/// off, and lockfile `--frozen` whenever a lockfile is provided.
library;

import 'package:path/path.dart' as p;

/// Hosts the sandboxed process may connect to by default.
const Set<String> defaultAllowedHosts = {
  'jsr.io',
  'registry.npmjs.org',
  'esm.sh',
};

/// Env vars the sandboxed process may read by default.
///
/// The list is deliberately narrow. `MIGRATIONS_DIR` is the one we set
/// ourselves; the rest are probe-points used by common npm packages
/// (`readable-stream`, `graceful-fs`, `bluebird`, `exceljs`). Without
/// these granted, those packages throw at import time.
const Set<String> defaultAllowedEnv = {
  'MIGRATIONS_DIR',
  'READABLE_STREAM',
  'GRACEFUL_FS_PLATFORM',
  'TEST_GRACEFUL_FS_GLOBAL_PATCH',
  'NODE_DEBUG',
  'BLUEBIRD_DEBUG',
  'BLUEBIRD_WARNINGS',
  'BLUEBIRD_LONG_STACK_TRACES',
  'BLUEBIRD_W_FORGOTTEN_RETURN',
  'NODE_ENV',
};

/// Immutable description of what a sandboxed script is permitted to do.
final class SandboxPolicy {
  const SandboxPolicy({
    this.allowedHosts = defaultAllowedHosts,
    this.allowedEnv = defaultAllowedEnv,
    this.allowSys = false,
    this.allowArbitraryPackages = false,
    this.lockfilePath,
  });

  /// Outbound hosts the sandboxed process may reach via `fetch`, module
  /// resolution, etc. Passed to `--allow-net=...`.
  final Set<String> allowedHosts;

  /// Environment variables the sandboxed process may read.
  /// Passed to `--allow-env=...`.
  final Set<String> allowedEnv;

  /// Whether to grant `--allow-sys`. Off by default.
  final bool allowSys;

  /// When `false` (default) and a lockfile is provided, `--frozen` is
  /// enforced: any import outside the lockfile's entries fails.
  /// When `true`, `--no-lock` is emitted so arbitrary imports resolve
  /// without lockfile validation.
  final bool allowArbitraryPackages;

  /// Optional lockfile path. `null` disables lockfile enforcement
  /// regardless of [allowArbitraryPackages].
  final String? lockfilePath;

  /// Builds the Deno CLI flags that enforce this policy against a specific
  /// request.
  ///
  /// `--allow-ffi` is emitted unscoped: Deno 2.x treats path-scoped FFI as
  /// applying only to `Deno.dlopen` path validation, so pointer operations
  /// (`UnsafePointer.of`, `UnsafeCallback`, etc.) fail with `NotCapable`
  /// under any non-empty path list. Defense-in-depth for FFI comes from the
  /// tight `--allow-write` and `--allow-read` scopes, which prevent a
  /// sandboxed script from *placing* a new native library anywhere loadable.
  ///
  /// Every path argument must be absolute; the caller is responsible.
  List<String> buildFlags({
    required String scriptPath,
    required String workingDirectory,
    required String migrationsPath,
    String? denoCacheDir,
  }) {
    final scriptDir = p.dirname(scriptPath);
    final readPaths = <String>[
      workingDirectory,
      scriptDir,
      migrationsPath,
      ?denoCacheDir,
    ];

    final flags = <String>[
      '--allow-read=${readPaths.join(',')}',
      '--allow-write=$workingDirectory',
      '--allow-net=${allowedHosts.join(',')}',
      '--allow-ffi',
      '--deny-run',
      '--allow-env=${allowedEnv.join(',')}',
    ];

    if (allowSys) {
      flags.add('--allow-sys');
    }

    if (lockfilePath != null && !allowArbitraryPackages) {
      flags.add('--lock=$lockfilePath');
      flags.add('--frozen');
    } else {
      flags.add('--no-lock');
    }

    return flags;
  }
}
