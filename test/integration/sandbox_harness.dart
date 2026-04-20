import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:quiver_sandbox/quiver_sandbox.dart';
import 'package:test/test.dart';

typedef ResultVerifier =
    void Function(
      SandboxResult result,
      StringBuffer output,
      List<SandboxEvent> events,
    );

/// Discovers every `.ts` fixture under `test/fixtures/<folder>/` (excluding
/// those beginning with `_`) and generates a test per fixture.
///
/// Each test is run with a fresh temp `workingDirectory` that is deleted in
/// `tearDown`. The [verify] callback receives the terminal result, the
/// captured output text, and the list of events emitted during the run.
void sandboxFixtureTests({
  required String folder,
  required ResultVerifier verify,
  SandboxPolicy? policy,
  Duration timeout = const Duration(seconds: 30),
  int maxOutputBytes = 10 * 1024 * 1024,
}) {
  late String workingDirectory;
  late String migrationsPath;
  late QuiverSandbox sandbox;

  setUpAll(() {
    final probe = Process.runSync(
      'deno',
      ['--version'],
      runInShell: Platform.isWindows,
    );
    if (probe.exitCode != 0) {
      throw StateError('Deno is not installed or not on PATH');
    }
  });

  setUp(() {
    workingDirectory = Directory.systemTemp
        .createTempSync('qsb_${folder}_')
        .path;
    migrationsPath = p.normalize(
      p.absolute(p.join('test', 'data', 'migrations')),
    );
    sandbox = QuiverSandbox(defaultPolicy: policy ?? const SandboxPolicy());
  });

  tearDown(() {
    final dir = Directory(workingDirectory);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  final fixtureDir = Directory(
    p.normalize(p.absolute(p.join('test', 'fixtures', folder))),
  );
  final fixtures = fixtureDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.ts'))
      .where((f) => !p.basename(f.path).startsWith('_'));

  for (final fixture in fixtures) {
    final name = p.basename(fixture.path);
    test(name, () async {
      final output = StringBuffer();
      final events = <SandboxEvent>[];
      final result = await sandbox.execute(
        SandboxRequest(
          scriptPath: p.normalize(p.absolute(fixture.path)),
          workingDirectory: workingDirectory,
          migrationsPath: migrationsPath,
          timeout: timeout,
          maxOutputBytes: maxOutputBytes,
          onOutput: output.write,
          onEvent: events.add,
        ),
      );
      verify(result, output, events);
    });
  }
}
