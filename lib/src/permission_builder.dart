import 'package:path/path.dart' as p;

import 'sandbox_config.dart';

/// Builds the Deno permission flags from a [SandboxConfig].
class PermissionBuilder {
  const PermissionBuilder();

  /// Returns the list of Deno CLI flags that enforce the sandbox permissions.
  ///
  /// Throws [ArgumentError] if any path in [config] is not absolute.
  List<String> buildFlags(SandboxConfig config) {
    _validateAbsolute('scriptPath', config.scriptPath);
    _validateAbsolute('databasePath', config.databasePath);
    _validateAbsolute('outputDir', config.outputDir);
    for (var i = 0; i < config.additionalReadPaths.length; i++) {
      _validateAbsolute('additionalReadPaths[$i]', config.additionalReadPaths[i]);
    }

    final scriptDir = p.dirname(config.scriptPath);
    final readPaths = [
      config.databasePath,
      scriptDir,
      ...config.additionalReadPaths,
      if (config.denoCacheDir != null) config.denoCacheDir!,
    ];
    final ffiPaths = [
      config.databasePath,
      if (config.denoCacheDir != null) config.denoCacheDir!,
    ];

    return [
      '--allow-read=${readPaths.join(',')}',
      '--allow-write=${config.databasePath},${config.outputDir}',
      '--allow-net=${config.allowedNetHosts.join(',')}',
      '--allow-ffi=${ffiPaths.join(',')}',
      '--deny-run',
      if (config.allowEnv) '--allow-env' else '--deny-env',
      if (config.allowSys) '--allow-sys' else '--deny-sys',
    ];
  }

  void _validateAbsolute(String name, String path) {
    if (!p.isAbsolute(path)) {
      throw ArgumentError.value(path, name, 'must be an absolute path');
    }
  }
}
