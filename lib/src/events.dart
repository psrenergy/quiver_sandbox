/// Structured events emitted during sandbox execution.
///
/// Consumers pass an `onEvent` callback in [SandboxRequest] to observe
/// lifecycle events, output chunks, permission violations, and abnormal
/// terminations in real time.
library;

import 'result.dart';

/// Base type for every event the sandbox can emit.
sealed class SandboxEvent {
  const SandboxEvent();
}

/// A chunk of text produced by the sandboxed process.
///
/// Emitted for every readable chunk on either stream before any buffering
/// or transformation. [isStderr] distinguishes stdout from stderr.
final class OutputChunkEvent extends SandboxEvent {
  const OutputChunkEvent({required this.text, required this.isStderr});

  final String text;
  final bool isStderr;
}

/// Emitted once the Deno subprocess has started successfully.
final class ProcessStartedEvent extends SandboxEvent {
  const ProcessStartedEvent(this.pid);

  final int pid;
}

/// Emitted when the Deno subprocess has finished, cleanly or otherwise.
///
/// The [reason] reflects *why* the process ended — see [TerminationReason].
final class ProcessExitedEvent extends SandboxEvent {
  const ProcessExitedEvent({required this.exitCode, required this.reason});

  final int exitCode;
  final TerminationReason reason;
}

/// A permission-violation line was detected in stderr.
///
/// Parsed from Deno's standard `NotCapable: Requires <capability> access ...`
/// error format. [capability] is e.g. `"net"`, `"read"`, `"ffi"`, etc.
/// [detail] is the quoted target (path, host, env var name) when present.
final class PermissionViolationEvent extends SandboxEvent {
  const PermissionViolationEvent({required this.capability, required this.detail});

  final String capability;
  final String detail;
}

/// The configured timeout elapsed before the process exited on its own.
///
/// The runner has already sent a SIGKILL by the time this event fires.
final class TimeoutEvent extends SandboxEvent {
  const TimeoutEvent(this.elapsed);

  final Duration elapsed;
}

/// Combined stdout+stderr output exceeded [SandboxRequest.maxOutputBytes].
///
/// The runner has already sent a SIGKILL by the time this event fires.
final class OutputCapEvent extends SandboxEvent {
  const OutputCapEvent(this.bytesEmitted);

  final int bytesEmitted;
}
