import 'dart:io';

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

/// Runs Deno scripts as subprocesses.
class DenoRunner {
  /// Path to the Deno executable. Defaults to `"deno"` (assumes it's on PATH).
  final String denoExecutable;

  const DenoRunner({this.denoExecutable = 'deno'});

  /// Runs a Deno script at [scriptPath] with the given positional [args].
  ///
  /// [denoFlags] are passed to `deno run` before the script path
  /// (e.g. `['--allow-read', '--allow-net']`).
  ///
  /// [workingDirectory] sets the working directory for the subprocess.
  Future<DenoResult> run(
    String scriptPath,
    List<String> args, {
    List<String> denoFlags = const [],
    String? workingDirectory,
  }) async {
    final arguments = [
      'run',
      ...denoFlags,
      scriptPath,
      ...args,
    ];

    final process = await Process.run(
      denoExecutable,
      arguments,
      workingDirectory: workingDirectory,
    );

    return DenoResult(
      stdout: process.stdout as String,
      stderr: process.stderr as String,
      exitCode: process.exitCode,
    );
  }
}
