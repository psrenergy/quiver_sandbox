/// Configuration for running a Deno script in the QuiverSandbox.
class SandboxConfig {
  /// Path to the .ts or .js script to execute.
  final String scriptPath;

  /// Path to the QuiverDB database directory.
  final String databasePath;

  /// Directory where the script writes output files (HTML, PDF, Excel).
  final String outputDir;

  /// Additional directories the script is allowed to read from.
  /// Added to `--allow-read` alongside databasePath and scriptDir.
  final List<String> additionalReadPaths;

  /// Positional arguments forwarded to the Deno script.
  final List<String> args;

  /// Network hosts the script is allowed to reach (for npm: imports).
  /// Defaults to `['registry.npmjs.org', 'esm.sh']`.
  final List<String> allowedNetHosts;

  /// Deno cache directory (for npm packages and native binaries like Koffi).
  /// Added to `--allow-read` and `--allow-ffi` so npm: imports with native
  /// bindings can load. If `null`, [QuiverSandbox] auto-detects via `deno info`.
  final String? denoCacheDir;

  /// Whether to allow environment variable access (`--allow-env`).
  /// Defaults to `true` because many npm packages (readable-stream, graceful-fs,
  /// bluebird, etc.) read env vars for feature detection and fail under Deno
  /// without this permission.
  final bool allowEnv;

  /// Whether to allow system info access (`--allow-sys`).
  /// Defaults to `false` (`--deny-sys`).
  /// Set to `true` if Koffi/QuiverDB needs OS/arch detection.
  final bool allowSys;

  /// Optional timeout for the Deno subprocess.
  final Duration? timeout;

  const SandboxConfig({
    required this.scriptPath,
    required this.databasePath,
    required this.outputDir,
    this.additionalReadPaths = const [],
    this.args = const [],
    this.allowedNetHosts = const ['registry.npmjs.org', 'esm.sh'],
    this.denoCacheDir,
    this.allowEnv = true,
    this.allowSys = false,
    this.timeout,
  });
}
