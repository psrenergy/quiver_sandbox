/// Resolves the Deno cache directory via `deno info --json`.
///
/// Results are memoized per (executable) combination for the lifetime of the
/// Dart isolate; an in-flight lookup is coalesced so concurrent callers share
/// one subprocess invocation.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

final Map<String, String?> _cached = {};
final Map<String, Future<String?>> _inFlight = {};

/// Returns the absolute path to Deno's cache directory, or `null` if the
/// lookup fails for any reason.
Future<String?> resolveDenoCacheDir(String denoExecutable) async {
  if (_cached.containsKey(denoExecutable)) {
    return _cached[denoExecutable];
  }
  final existing = _inFlight[denoExecutable];
  if (existing != null) return existing;

  final future = _lookup(denoExecutable);
  _inFlight[denoExecutable] = future;
  try {
    final result = await future;
    _cached[denoExecutable] = result;
    return result;
  } finally {
    _inFlight.remove(denoExecutable);
  }
}

Future<String?> _lookup(String denoExecutable) async {
  try {
    final result = await Process.run(denoExecutable, [
      'info',
      '--json',
    ], runInShell: Platform.isWindows);
    if (result.exitCode != 0) return null;
    final info = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    return info['denoDir'] as String?;
  } on Exception {
    return null;
  }
}

/// Clears the memoized cache. Intended for tests.
void resetDenoCacheDirForTest() {
  _cached.clear();
  _inFlight.clear();
}
