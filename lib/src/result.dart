/// Outcome types for [QuiverSandbox.execute].
library;

/// Why a sandboxed process ended.
enum TerminationReason {
  /// The process exited on its own (zero or non-zero).
  completed,

  /// The configured timeout elapsed; the runner killed the process.
  timedOut,

  /// The combined stdout+stderr output exceeded the configured cap; the
  /// runner killed the process to prevent further emission.
  outputCapExceeded,

  /// The process was killed by a signal outside the runner's control
  /// (e.g. OS shutdown). Rare.
  killed,

  /// `Process.start` itself threw — the Deno subprocess never launched.
  /// [SandboxResult.exitCode] is `-1` in this case.
  startFailure,
}

/// The result of a single [QuiverSandbox.execute] call.
final class SandboxResult {
  const SandboxResult({
    required this.exitCode,
    required this.elapsed,
    required this.outputBytesEmitted,
    required this.reason,
  });

  /// Exit code reported by the Deno subprocess.
  ///
  /// `-1` when [reason] is [TerminationReason.startFailure].
  /// `0` typically means success. Non-zero covers everything else —
  /// script threw, Deno denied a permission, etc.
  final int exitCode;

  /// Wall-clock duration between subprocess launch and termination.
  final Duration elapsed;

  /// Total bytes emitted across stdout and stderr (in UTF-8).
  final int outputBytesEmitted;

  /// Why the process ended. See [TerminationReason].
  final TerminationReason reason;
}
