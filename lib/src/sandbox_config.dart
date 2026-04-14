/// Configuration for running a Deno script in the QuiverSandbox.
class SandboxConfig {
  /// Path to the .ts or .js script to execute.
  final String scriptPath;

  /// Path to the QuiverDB database directory.
  final String databasePath;

  /// Directory where the script writes output files (HTML, PDF, Excel).
  final String outputDir;

  /// Positional arguments forwarded to the Deno script.
  final List<String> args;

  /// Network hosts the script is allowed to reach (for npm: imports).
  /// Defaults to `['registry.npmjs.org', 'esm.sh']`.
  final List<String> allowedNetHosts;

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
    this.args = const [],
    this.allowedNetHosts = const ['registry.npmjs.org', 'esm.sh'],
    this.allowSys = false,
    this.timeout,
  });
}
