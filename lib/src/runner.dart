/// Executes a [SandboxRequest] under a pre-built flag set.
///
/// Handles three things beyond `Process.start`:
/// 1. Wall-clock timeout — kills the subprocess when [SandboxRequest.timeout]
///    elapses.
/// 2. Output cap — kills the subprocess when combined stdout+stderr bytes
///    exceed [SandboxRequest.maxOutputBytes].
/// 3. Event emission — parses Deno's permission-violation stderr format and
///    emits structured events in addition to raw text chunks.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'events.dart';
import 'request.dart';
import 'result.dart';

/// Matches Deno's standard permission-denied error line, e.g.:
///   error: Uncaught (in promise) NotCapable: Requires net access to "example.com", run again with the --allow-net flag
///   NotCapable: Requires ffi access, run again with the --allow-ffi flag
final RegExp _violationRegex = RegExp(
  r'NotCapable:\s+Requires\s+(\w+)\s+access(?:\s+to\s+"([^"]+)")?',
);

class SandboxRunner {
  const SandboxRunner._();

  /// Kills [process] plus any child processes it may have spawned.
  ///
  /// On Windows `runInShell: true` wraps Deno in `cmd.exe`, so the Dart
  /// Process handle refers to the shell and `process.kill()` would orphan
  /// the child `deno.exe` (which holds `workingDirectory` open). Use
  /// `taskkill /F /T` to terminate the whole tree. On Unix, SIGKILL on the
  /// process group suffices.
  static Future<void> _forceKillTree(Process process) async {
    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
      } on ProcessException {
        // `taskkill` is shipped with Windows and effectively always present,
        // so we never expect to land here. If it does, accept the failure —
        // at worst the child stays orphaned for a bit.
      }
    } else {
      process.kill(ProcessSignal.sigkill);
    }
  }

  /// Runs the subprocess, streaming output and enforcing limits.
  static Future<SandboxResult> run({
    required SandboxRequest request,
    required List<String> flags,
    required String denoExecutable,
  }) async {
    final stopwatch = Stopwatch()..start();
    final onEvent = request.onEvent;
    final onOutput = request.onOutput;

    final arguments = <String>['run', ...flags, request.scriptPath];

    final Process process;
    try {
      process = await Process.start(
        denoExecutable,
        arguments,
        runInShell: Platform.isWindows,
        workingDirectory: request.workingDirectory,
        environment: <String, String>{
          'MIGRATIONS_DIR': request.migrationsPath,
          ...?request.extraEnv,
        },
      );
    } on ProcessException {
      stopwatch.stop();
      onEvent?.call(
        const ProcessExitedEvent(
          exitCode: -1,
          reason: TerminationReason.startFailure,
        ),
      );
      return SandboxResult(
        exitCode: -1,
        elapsed: stopwatch.elapsed,
        outputBytesEmitted: 0,
        reason: TerminationReason.startFailure,
      );
    }

    onEvent?.call(ProcessStartedEvent(process.pid));

    var outputBytes = 0;
    var capExceeded = false;
    var timedOut = false;

    void handleChunk(String text, {required bool isStderr}) {
      if (capExceeded || timedOut) return;
      outputBytes += utf8.encode(text).length;
      if (outputBytes > request.maxOutputBytes) {
        capExceeded = true;
        onEvent?.call(OutputCapEvent(outputBytes));
        unawaited(_forceKillTree(process));
        return;
      }
      onOutput?.call(text);
      onEvent?.call(OutputChunkEvent(text: text, isStderr: isStderr));
      if (isStderr) {
        final match = _violationRegex.firstMatch(text);
        if (match != null) {
          onEvent?.call(
            PermissionViolationEvent(
              capability: match.group(1)!,
              detail: match.group(2) ?? '',
            ),
          );
        }
      }
    }

    final stdoutDone = process.stdout
        .transform(const Utf8Decoder())
        .listen((chunk) => handleChunk(chunk, isStderr: false))
        .asFuture<void>();

    final stderrDone = process.stderr
        .transform(const Utf8Decoder())
        .listen((chunk) => handleChunk(chunk, isStderr: true))
        .asFuture<void>();

    Timer? timeoutTimer;
    if (request.timeout > Duration.zero) {
      timeoutTimer = Timer(request.timeout, () {
        if (capExceeded) return;
        timedOut = true;
        onEvent?.call(TimeoutEvent(stopwatch.elapsed));
        unawaited(_forceKillTree(process));
      });
    }

    final exitCode = await process.exitCode;
    timeoutTimer?.cancel();
    // Wait for output streams to drain so onOutput/events from in-flight
    // chunks are delivered before the result is returned.
    await Future.wait<void>([stdoutDone, stderrDone]);
    stopwatch.stop();

    final TerminationReason reason;
    if (timedOut) {
      reason = TerminationReason.timedOut;
    } else if (capExceeded) {
      reason = TerminationReason.outputCapExceeded;
    } else {
      reason = TerminationReason.completed;
    }

    onEvent?.call(ProcessExitedEvent(exitCode: exitCode, reason: reason));

    return SandboxResult(
      exitCode: exitCode,
      elapsed: stopwatch.elapsed,
      outputBytesEmitted: outputBytes,
      reason: reason,
    );
  }
}
