import 'dart:convert';
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

  QuiverSandbox({
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
    // Resolve Deno cache dir if not explicitly provided.
    final resolvedConfig = config.denoCacheDir != null
        ? config
        : SandboxConfig(
            scriptPath: config.scriptPath,
            databasePath: config.databasePath,
            outputDir: config.outputDir,
            additionalReadPaths: config.additionalReadPaths,
            args: config.args,
            allowedNetHosts: config.allowedNetHosts,
            denoCacheDir: await _resolveDenoCacheDir(),
            allowSys: config.allowSys,
            timeout: config.timeout,
          );

    final flags = _permissionBuilder.buildFlags(resolvedConfig);

    final arguments = [
      'run',
      ...flags,
      resolvedConfig.scriptPath,
      ...resolvedConfig.args,
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

  String? _cachedDenoCacheDir;

  /// Auto-detects the Deno cache directory via `deno info --json`.
  Future<String?> _resolveDenoCacheDir() async {
    if (_cachedDenoCacheDir != null) return _cachedDenoCacheDir;

    try {
      final result = await Process.run(
        denoExecutable,
        ['info', '--json'],
        runInShell: Platform.isWindows,
      );
      if (result.exitCode == 0) {
        final info = jsonDecode(result.stdout as String) as Map<String, dynamic>;
        _cachedDenoCacheDir = info['denoDir'] as String?;
      }
    } on Exception {
      // Ignore — denoCacheDir will be null and omitted from permissions.
    }
    return _cachedDenoCacheDir;
  }
}
