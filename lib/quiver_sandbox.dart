/// A Dart library for running Deno scripts in a permission-scoped sandbox.
///
/// The public API is small: construct a [QuiverSandbox] with a default
/// [SandboxPolicy] and call [QuiverSandbox.execute] with a [SandboxRequest].
/// The result carries the exit code plus the reason the process ended —
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
export 'src/policy.dart'
    show SandboxPolicy, defaultAllowedEnv, defaultAllowedHosts;
export 'src/request.dart' show SandboxRequest;
export 'src/result.dart' show SandboxResult, TerminationReason;

/// Entry point for executing Deno scripts under a permission-scoped sandbox.
final class QuiverSandbox {
  QuiverSandbox({
    this.denoExecutable = 'deno',
    this.defaultPolicy = const SandboxPolicy(),
  });

  /// Path to the Deno executable. Defaults to `"deno"` (resolved via PATH).
  final String denoExecutable;

  /// Policy used when [SandboxRequest.policy] is omitted.
  final SandboxPolicy defaultPolicy;

  /// Absolute filesystem path to the lockfile that ships with this package
  /// (`lockfile/deno.lock`). Feed the result to [SandboxPolicy.lockfilePath]
  /// to run scripts under the package's canonical allowlist.
  ///
  /// See [bundled_lockfile.resolveBundledLockfilePath] for caveats.
  static Future<String> resolveBundledLockfilePath() =>
      bundled_lockfile.resolveBundledLockfilePath();

  /// Executes [request]. Returns a [SandboxResult] describing how the
  /// process ended and how much output it produced.
  Future<SandboxResult> execute(SandboxRequest request) async {
    final policy = request.policy ?? defaultPolicy;
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

