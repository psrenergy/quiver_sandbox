import 'package:path/path.dart' as p;

/// Builds the Deno permission flags for the QuiverSandbox.
///
/// Security settings are hardcoded:
/// - Network: registry.npmjs.org, esm.sh
/// - Env: allowed (npm packages need process.env)
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
    List<String> additionalReadPaths = const [],
    String? denoCacheDir,
  }) {
    _validateAbsolute('scriptPath', scriptPath);
    _validateAbsolute('databasePath', databasePath);
    _validateAbsolute('outputDir', outputDir);
    for (var i = 0; i < additionalReadPaths.length; i++) {
      _validateAbsolute('additionalReadPaths[$i]', additionalReadPaths[i]);
    }

    final scriptDir = p.dirname(scriptPath);
    final readPaths = [
      databasePath,
      scriptDir,
      ...additionalReadPaths,
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
      '--allow-env',
      '--allow-sys',
    ];
  }

  void _validateAbsolute(String name, String path) {
    if (!p.isAbsolute(path)) {
      throw ArgumentError.value(path, name, 'must be an absolute path');
    }
  }
}
