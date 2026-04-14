import 'dart:io';

import 'permission_builder.dart';
import 'sandbox_config.dart';

/// The result of running a Deno script.
class DenoResult {
  final String stdout;
  final String stderr;
  final int exitCode;

  const DenoResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  /// Whether the script exited successfully (exit code 0).
  bool get success => exitCode == 0;
}

/// Executes Deno scripts inside a permission-scoped sandbox.
class QuiverSandbox {
  /// Path to the Deno executable. Defaults to `"deno"` (assumes it's on PATH).
  final String denoExecutable;

  final PermissionBuilder _permissionBuilder;

  const QuiverSandbox({
    this.denoExecutable = 'deno',
    PermissionBuilder permissionBuilder = const PermissionBuilder(),
  }) : _permissionBuilder = permissionBuilder;

  /// Executes the script described by [config] in a sandboxed Deno process.
  ///
  /// The sandbox enforces:
  /// - Read access scoped to database and script directories
  /// - Write access scoped to the output directory
  /// - Network access scoped to npm registries
  /// - FFI access scoped to the database directory (for Koffi/QuiverDB)
  /// - Subprocess spawning denied
  /// - System info access denied by default (toggle via [SandboxConfig.allowSys])
  Future<DenoResult> execute(SandboxConfig config) async {
    final flags = _permissionBuilder.buildFlags(config);

    final arguments = [
      'run',
      ...flags,
      config.scriptPath,
      ...config.args,
    ];

    final process = await Process.run(
      denoExecutable,
      arguments,
      runInShell: Platform.isWindows,
    );

    return DenoResult(
      stdout: process.stdout as String,
      stderr: process.stderr as String,
      exitCode: process.exitCode,
    );
  }
}
