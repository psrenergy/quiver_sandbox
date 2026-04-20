/// Resolves the filesystem path of the lockfile that ships with this package.
///
/// The host app — the sole consumer of this internal package — uses this to
/// feed [SandboxPolicy.lockfilePath] without hardcoding a brittle relative
/// path into its own codebase.
library;

import 'dart:isolate';

import 'package:path/path.dart' as p;

/// Returns the absolute path to `lockfile/deno.lock` within this package.
///
/// Uses [Isolate.resolvePackageUri] to locate `lib/quiver_sandbox.dart`,
/// then walks up two levels to the package root. Works under `dart run`,
/// `dart test`, and `path:` dependencies in a workspace — i.e., every
/// scenario relevant to an internal POC.
///
/// Throws [StateError] if the package URI cannot be resolved. This happens
/// if the caller's pubspec doesn't declare `quiver_sandbox`, or if the
/// code is running inside an AOT snapshot where the original source tree
/// is no longer on disk (out of scope for the current POC).
Future<String> resolveBundledLockfilePath() async {
  final libUri = await Isolate.resolvePackageUri(
    Uri.parse('package:quiver_sandbox/quiver_sandbox.dart'),
  );
  if (libUri == null) {
    throw StateError(
      "Cannot resolve 'package:quiver_sandbox/' — is the package declared "
      "in the consumer's pubspec.yaml?",
    );
  }
  final libPath = libUri.toFilePath();
  final packageRoot = p.dirname(p.dirname(libPath));
  return p.join(packageRoot, 'lockfile', 'deno.lock');
}
