import 'package:quiver_sandbox/quiver_sandbox.dart';

void main() async {
  final runner = DenoRunner();

  // Run a Deno script with arguments and permission flags.
  final result = await runner.run(
    'script.ts',
    ['arg1', 'arg2'],
    denoFlags: ['--allow-read', '--allow-net'],
  );

  print('Exit code: ${result.exitCode}');
  print('Stdout: ${result.stdout}');
  print('Stderr: ${result.stderr}');
}
