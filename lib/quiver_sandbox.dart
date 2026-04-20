/// A Dart library for running Deno scripts in a permission-scoped sandbox.
///
/// The public API is deliberately small: construct a [QuiverSandbox] and
/// call [QuiverSandbox.execute] with a [SandboxRequest]. There is no policy
/// knob — the sandbox always enforces the same fixed security profile
/// (scoped read/write, curated net/env allowlist, `--frozen` against the
/// package's bundled lockfile, no subprocess, no sys info). The result
/// carries the exit code plus the reason the process ended —
/// completed, timed out, output cap exceeded, etc.
library;

import 'src/bundled_lockfile.dart' as bundled_lockfile;
import 'src/deno_info.dart';
import 'src/policy.dart';
import 'src/request.dart';
import 'src/result.dart';
import 'src/runner.dart';

export 'src/events.dart'
    show
        SandboxEvent,
        OutputChunkEvent,
        OutputCapEvent,
        PermissionViolationEvent,
        ProcessExitedEvent,
        ProcessStartedEvent,
        TimeoutEvent;
export 'src/request.dart' show SandboxRequest;
export 'src/result.dart' show SandboxResult, TerminationReason;

/// Entry point for executing Deno scripts under a permission-scoped sandbox.
///
/// The sandbox's security profile is fixed at the package level and is not
/// configurable by the host app. See `CLAUDE.md` for the rationale and the
/// exact flag set.
final class QuiverSandbox {
  QuiverSandbox({this.denoExecutable = 'deno'});

  /// Path to the Deno executable. Defaults to `"deno"` (resolved via PATH).
  final String denoExecutable;

  /// Executes [request]. Returns a [SandboxResult] describing how the
  /// process ended and how much output it produced.
  Future<SandboxResult> execute(SandboxRequest request) async {
    final lockfilePath = await bundled_lockfile.resolveBundledLockfilePath();
    final policy = SandboxPolicy(lockfilePath: lockfilePath);
    final denoCacheDir = await resolveDenoCacheDir(denoExecutable);

    final flags = policy.buildFlags(
      scriptPath: request.scriptPath,
      workingDirectory: request.workingDirectory,
      migrationsPath: request.migrationsPath,
      denoCacheDir: denoCacheDir,
    );

    return SandboxRunner.run(
      request: request,
      flags: flags,
      denoExecutable: denoExecutable,
    );
  }
}
