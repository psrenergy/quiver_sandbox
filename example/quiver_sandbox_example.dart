import 'dart:io';

import 'package:quiver_sandbox/quiver_sandbox.dart';

void main() async {
  final sandbox = QuiverSandbox();
  final exitCode = await sandbox.execute(
    scriptPath: '/path/to/reports/monthly.ts',
    databasePath: '/path/to/mydb',
    outputDir: '/tmp/output',
    args: ['--month', '2026-03'],
    writeInTerminal: stdout.write,
  );

  print('Exit code: $exitCode');
}
