/// Adds one or more packages to the sandbox's allowlist (`lockfile/deno.lock`).
///
/// Usage:
///
///     dart run tool/add_package.dart <spec>...
///
/// Each `<spec>` is a standard Deno module specifier (e.g. `npm:dayjs@1.11.10`,
/// `jsr:@std/cli@^1.0.0`). Run with no args to simply regenerate the lockfile
/// from the existing permit-fixture imports (useful after editing a fixture).
///
/// What it does:
///   1. Globs `test/fixtures/permit/*.ts` (skipping `_*.ts`).
///   2. If any specs are passed, writes them to a temp `.ts` as `import` stmts.
///   3. Invokes `deno cache --lock=lockfile/deno.lock --frozen=false` with
///      both the permit fixtures and the temp file.
///   4. Reports the result. Cleans up the temp file.
///
/// The lockfile ends up covering every import across the permit fixtures plus
/// the new specs. To permanently allow a spec, also add an `import` of it to
/// a permit fixture (or create a new one) so the package is exercised by tests.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final projectRoot = _findProjectRoot();
  if (projectRoot == null) {
    stderr.writeln(
      'error: run this script from inside the quiver_sandbox package.',
    );
    exit(2);
  }

  final permitDir = Directory(
    p.join(projectRoot, 'test', 'fixtures', 'permit'),
  );
  if (!permitDir.existsSync()) {
    stderr.writeln('error: ${permitDir.path} does not exist.');
    exit(2);
  }

  final fixtures =
      permitDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.ts'))
          .where((f) => !p.basename(f.path).startsWith('_'))
          .map((f) => f.path)
          .toList()
        ..sort();

  File? tempFile;
  if (args.isNotEmpty) {
    final tempDir = Directory.systemTemp.createTempSync('qsb_add_pkg_');
    tempFile = File(p.join(tempDir.path, 'extras.ts'));
    final body = args.map((spec) => 'import "$spec";').join('\n');
    tempFile.writeAsStringSync('$body\n');
  }

  final lockfile = p.join(projectRoot, 'lockfile', 'deno.lock');
  Directory(p.dirname(lockfile)).createSync(recursive: true);

  stdout.writeln('Regenerating $lockfile');
  for (final f in fixtures) {
    stdout.writeln('  + ${p.relative(f, from: projectRoot)}');
  }
  if (tempFile != null) {
    for (final spec in args) {
      stdout.writeln('  + new: $spec');
    }
  }
  stdout.writeln('');

  // Deno's `--frozen=false` only *appends* to the lockfile — it never prunes
  // stale entries. Delete the file first so the regeneration reflects exactly
  // the current inputs (fixtures + any new specs).
  final lockfileHandle = File(lockfile);
  if (lockfileHandle.existsSync()) {
    lockfileHandle.deleteSync();
  }

  final result = await Process.run('deno', [
    'cache',
    '--lock=$lockfile',
    '--frozen=false',
    ...fixtures,
    if (tempFile != null) tempFile.path,
  ], runInShell: Platform.isWindows);

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (tempFile != null) {
    try {
      tempFile.parent.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort — the OS will reap it.
    }
  }

  if (result.exitCode != 0) {
    stderr.writeln('\nfailed: deno cache exited with ${result.exitCode}');
    exit(result.exitCode);
  }

  stdout.writeln(
    '\nok: $lockfile updated. Commit it and remember to add a '
    'permit fixture that imports any new spec so it stays exercised by tests.',
  );
}

String? _findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}
