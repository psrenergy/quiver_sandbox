import 'package:quiver_sandbox/quiver_sandbox.dart';

void main() async {
  final config = SandboxConfig(
    scriptPath: '/path/to/reports/monthly.ts',
    databasePath: '/path/to/mydb',
    outputDir: '/tmp/output',
    args: ['--month', '2026-03'],
  );

  final runner = QuiverSandbox();
  final result = await runner.execute(config);

  print('Exit code: ${result.exitCode}');
  print('Success: ${result.success}');
  if (result.stdout.isNotEmpty) print('Stdout:\n${result.stdout}');
  if (result.stderr.isNotEmpty) print('Stderr:\n${result.stderr}');
}
