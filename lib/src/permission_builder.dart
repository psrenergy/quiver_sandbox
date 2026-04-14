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

    final scriptDir = p.dirname(config.scriptPath);

    return [
      '--allow-read=${config.databasePath},$scriptDir',
      '--allow-write=${config.outputDir}',
      '--allow-net=${config.allowedNetHosts.join(',')}',
      '--allow-ffi=${config.databasePath}',
      '--deny-run',
      if (config.allowSys) '--allow-sys' else '--deny-sys',
    ];
  }

  void _validateAbsolute(String name, String path) {
    if (!p.isAbsolute(path)) {
      throw ArgumentError.value(path, name, 'must be an absolute path');
    }
  }
}
