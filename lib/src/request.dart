/// Input type for [QuiverSandbox.execute].
library;

import 'package:path/path.dart' as p;

import 'events.dart';
import 'policy.dart';

/// Single request to execute a Deno script inside the sandbox.
///
/// All path fields must be absolute; the constructor validates this upfront.
final class SandboxRequest {
  SandboxRequest({
    required this.scriptPath,
    required this.workingDirectory,
    required this.migrationsPath,
    this.policy,
    this.timeout = const Duration(seconds: 30),
    this.maxOutputBytes = 10 * 1024 * 1024,
    this.onOutput,
    this.onEvent,
    this.extraEnv,
  }) {
    _validateAbsolute('scriptPath', scriptPath);
    _validateAbsolute('workingDirectory', workingDirectory);
    _validateAbsolute('migrationsPath', migrationsPath);
    if (maxOutputBytes <= 0) {
      throw ArgumentError.value(
        maxOutputBytes,
        'maxOutputBytes',
        'must be greater than zero',
      );
    }
  }

  /// Absolute path to the `.ts`/`.js` script that Deno will run.
  final String scriptPath;

  /// Absolute path used as the subprocess `cwd`, the read/write root, and
  /// the effective "ephemeral" workspace for this execution.
  final String workingDirectory;

  /// Absolute path to the QuiverDB migrations directory. Exposed to the
  /// script via the `MIGRATIONS_DIR` environment variable and added to
  /// `--allow-read`.
  final String migrationsPath;

  /// Policy override. When `null`, [QuiverSandbox.defaultPolicy] applies.
  final SandboxPolicy? policy;

  /// Maximum wall-clock duration. When reached, the runner kills the
  /// process and marks the result as [TerminationReason.timedOut].
  ///
  /// Pass [Duration.zero] to disable (not recommended).
  final Duration timeout;

  /// Maximum combined bytes emitted across stdout and stderr. When
  /// exceeded, the runner kills the process and marks the result as
  /// [TerminationReason.outputCapExceeded].
  final int maxOutputBytes;

  /// Receives each chunk of decoded output text as it arrives. Called on
  /// both stdout and stderr streams.
  final void Function(String text)? onOutput;

  /// Receives every structured event emitted during execution. Fires
  /// strictly more events than [onOutput] (lifecycle, violations, etc.).
  final void Function(SandboxEvent event)? onEvent;

  /// Extra env vars to inject into the subprocess alongside `MIGRATIONS_DIR`.
  /// Note: each key must also appear in [SandboxPolicy.allowedEnv], otherwise
  /// the script can't read them (Deno denies at runtime).
  final Map<String, String>? extraEnv;

  void _validateAbsolute(String name, String value) {
    if (!p.isAbsolute(value)) {
      throw ArgumentError.value(value, name, 'must be an absolute path');
    }
  }
}
