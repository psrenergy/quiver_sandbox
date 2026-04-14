import 'dart:convert';
import 'dart:io';

import 'permission_builder.dart';
import 'sandbox_config.dart';

/// Executes Deno scripts inside a permission-scoped sandbox.
class QuiverSandbox {
  /// Path to the Deno executable. Defaults to `"deno"` (assumes it's on PATH).
  final String denoExecutable;

  final PermissionBuilder _permissionBuilder;

  QuiverSandbox({
    this.denoExecutable = 'deno',
  }) : _permissionBuilder = const PermissionBuilder();

  /// Executes a Deno script in a sandboxed process.
  ///
  /// Output (stdout and stderr) is streamed to [writeInTerminal] in real-time.
  /// Returns the process exit code.
  ///
  /// The sandbox enforces:
  /// - Read access scoped to [databasePath], script directory, and [additionalReadPaths]
  /// - Write access scoped to [databasePath] and [outputDir]
  /// - Network access scoped to [allowedNetHosts] (npm registries by default)
  /// - FFI access scoped to [databasePath] and Deno cache (for Koffi/QuiverDB)
  /// - Subprocess spawning denied
  /// - System info access denied by default (toggle via [allowSys])
  Future<int> execute({
    required String scriptPath,
    required String databasePath,
    required String outputDir,
    required void Function(String) writeInTerminal,
    List<String> args = const [],
    List<String> additionalReadPaths = const [],
    List<String> allowedNetHosts = const ['registry.npmjs.org', 'esm.sh'],
    String? denoCacheDir,
    bool allowSys = false,
    Duration? timeout,
  }) async {
    final resolvedCacheDir = denoCacheDir ?? await _resolveDenoCacheDir();

    final config = SandboxConfig(
      scriptPath: scriptPath,
      databasePath: databasePath,
      outputDir: outputDir,
      additionalReadPaths: additionalReadPaths,
      args: args,
      allowedNetHosts: allowedNetHosts,
      denoCacheDir: resolvedCacheDir,
      allowSys: allowSys,
      timeout: timeout,
    );

    final flags = _permissionBuilder.buildFlags(config);

    final arguments = [
      'run',
      ...flags,
      config.scriptPath,
      ...config.args,
    ];

    final process = await Process.start(
      denoExecutable,
      arguments,
      runInShell: Platform.isWindows,
    );

    process.stdout.transform(const Utf8Decoder()).listen(writeInTerminal);
    process.stderr.transform(const Utf8Decoder()).listen(writeInTerminal);

    return process.exitCode;
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
        final info =
            jsonDecode(result.stdout as String) as Map<String, dynamic>;
        _cachedDenoCacheDir = info['denoDir'] as String?;
      }
    } on Exception {
      // Ignore — denoCacheDir will be null and omitted from permissions.
    }
    return _cachedDenoCacheDir;
  }
}
