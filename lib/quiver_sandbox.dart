/// A Dart library for running Deno scripts in a permission-scoped sandbox.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Builds the Deno permission flags for the QuiverSandbox.
///
/// Security settings are hardcoded:
/// - Network: registry.npmjs.org, esm.sh
/// - Env: denied (no environment variable access)
/// - Sys: allowed (Koffi/QuiverDB needs OS/arch detection)
/// - Run: denied (no subprocess spawning)
class PermissionBuilder {
  const PermissionBuilder();

  /// Returns the list of Deno CLI flags that enforce the sandbox permissions.
  ///
  /// Throws [ArgumentError] if any path is not absolute.
  List<String> buildFlags({
    required String scriptPath,
    required String databasePath,
    required String outputDir,
    required String migrationsPath,
    String? denoCacheDir,
  }) {
    _validateAbsolute('scriptPath', scriptPath);
    _validateAbsolute('databasePath', databasePath);
    _validateAbsolute('outputDir', outputDir);
    _validateAbsolute('migrationsPath', migrationsPath);

    final scriptDir = p.dirname(scriptPath);
    final readPaths = [
      databasePath,
      scriptDir,
      migrationsPath,
      ?denoCacheDir,
    ];
    final ffiPaths = [
      databasePath,
      ?denoCacheDir,
    ];

    return [
      '--allow-read=${readPaths.join(',')}',
      '--allow-write=$databasePath,$outputDir',
      '--allow-net=registry.npmjs.org,esm.sh',
      '--allow-ffi=${ffiPaths.join(',')}',
      '--deny-run',
      '--deny-env',
      '--allow-sys',
    ];
  }

  void _validateAbsolute(String name, String path) {
    if (!p.isAbsolute(path)) {
      throw ArgumentError.value(path, name, 'must be an absolute path');
    }
  }
}

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
  /// - Read access scoped to [databasePath], script directory, and [migrationsPath]
  /// - Write access scoped to [databasePath] and [outputDir]
  /// - Network access scoped to npm registries (registry.npmjs.org, esm.sh)
  /// - FFI access scoped to [databasePath] and Deno cache (for Koffi/QuiverDB)
  /// - Environment variable access denied
  /// - System info access allowed (Koffi/QuiverDB needs OS/arch detection)
  /// - Subprocess spawning denied
  Future<int> execute({
    required String scriptPath,
    required String databasePath,
    required String outputDir,
    required void Function(String) writeInTerminal,
    List<String> args = const [],
    required String migrationsPath,
    Duration? timeout,
  }) async {
    final resolvedCacheDir = await _resolveDenoCacheDir();

    final flags = _permissionBuilder.buildFlags(
      scriptPath: scriptPath,
      databasePath: databasePath,
      outputDir: outputDir,
      migrationsPath: migrationsPath,
      denoCacheDir: resolvedCacheDir,
    );

    final arguments = [
      'run',
      ...flags,
      scriptPath,
      ...args,
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
