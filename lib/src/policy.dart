/// [SandboxPolicy] models the static part of a sandbox configuration —
/// what hosts, env vars, and packages the sandboxed code is allowed to touch.
///
/// This is an internal detail of [QuiverSandbox]. The public API of this
/// package does not expose policy configuration; there is exactly one fixed
/// policy enforced on every execution. The class is kept separately for
/// isolation in unit tests and to keep the flag-building logic pure.
library;

import 'package:path/path.dart' as p;

/// Outbound hosts the sandboxed process may reach.
const Set<String> allowedHosts = {'jsr.io', 'registry.npmjs.org', 'esm.sh'};

/// Env vars the sandboxed process may read.
///
/// Narrow on purpose. `MIGRATIONS_DIR` is set by the sandbox; the rest are
/// probe-points used by common npm packages (`readable-stream`,
/// `graceful-fs`, `bluebird`, `exceljs`). Without them granted, those
/// packages throw at import time.
const Set<String> allowedEnv = {
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
///
/// Fixed by design: hosts, env allowlist, sys denial, and lockfile-enforced
/// frozen mode are all hardcoded. The only piece provided at construction is
/// the path to the canonical lockfile, which is resolved at runtime by
/// `QuiverSandbox` via `resolveBundledLockfilePath`.
final class SandboxPolicy {
  const SandboxPolicy({required this.lockfilePath});

  /// Absolute path to the lockfile pinning every allowed module version.
  /// Emitted as `--lock=<path> --frozen`.
  final String lockfilePath;

  /// Builds the Deno CLI flags for a specific request.
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

    return [
      // Suppress auto-discovery of `deno.json`/`deno.jsonc` and any workspace
      // configs above the script's directory. Without this, Deno walks up
      // from `workingDirectory` until it hits user-home or drive root, which
      // on a real machine can find unrelated configs (e.g. other workspaces)
      // and try to reconcile their deps against our lockfile.
      '--no-config',
      '--allow-read=${readPaths.join(',')}',
      '--allow-write=$workingDirectory',
      '--allow-net=${allowedHosts.join(',')}',
      '--allow-ffi',
      '--deny-run',
      '--allow-env=${allowedEnv.join(',')}',
      '--lock=$lockfilePath',
      '--frozen',
    ];
  }
}
