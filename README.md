# quiver_sandbox

[![CI](https://github.com/psrenergy/quiver_sandbox/actions/workflows/ci.yml/badge.svg)](https://github.com/psrenergy/quiver_sandbox/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/psrenergy/quiver_sandbox/branch/master/graph/badge.svg)](https://codecov.io/gh/psrenergy/quiver_sandbox)

Internal Dart package for the PSR app that executes JS/TS scripts inside Deno's permission-scoped sandbox. Not published to pub.dev; depended on via `path:` from the host app and exists as a separately-packaged library so the sandbox's behavior can be tested in isolation.

Scripts access QuiverDB databases (`jsr:@psrenergy/quiver@^0.7.4`) and produce artefacts (HTML, JSON, Excel, PDF) inside an ephemeral working directory.

**The security profile is fixed at the package level** — there is no `SandboxPolicy` knob on the public API. Every execution runs under the same scoped read/write, curated net/env allowlist, frozen lockfile, and resource limits. Tweaking the profile means editing this package, not the host app.

## Requirements

- Dart SDK `^3.11.1`
- [Deno](https://deno.com/) `2.7+` on `PATH`

## Quick start

```dart
import 'dart:io';
import 'package:quiver_sandbox/quiver_sandbox.dart';

Future<void> main() async {
  final workdir = Directory.systemTemp.createTempSync('quiver_run_');
  final sandbox = QuiverSandbox();

  final result = await sandbox.execute(
    SandboxRequest(
      scriptPath: '/abs/path/to/user_script.ts',
      workingDirectory: workdir.path,
      migrationsPath: '/abs/path/to/migrations',
      timeout: const Duration(seconds: 30),
      maxOutputBytes: 10 * 1024 * 1024,
      onOutput: stdout.write,
      onEvent: (e) => stdout.writeln('[event] ${e.runtimeType}'),
    ),
  );

  print('exit=${result.exitCode} reason=${result.reason} '
      '(${result.elapsed.inMilliseconds} ms, ${result.outputBytesEmitted} bytes)');

  workdir.deleteSync(recursive: true);
}
```

A minimal `user_script.ts`:

```ts
import { Database } from "jsr:@psrenergy/quiver@^0.7.4";

const db = Database.fromMigrations("report.db", Deno.env.get("MIGRATIONS_DIR")!);
// ...read/write/query...
db.close();
```

The sandbox passes `MIGRATIONS_DIR` to the subprocess automatically.

## What the fixed policy enforces

| Permission            | Scope                                                                                        |
|-----------------------|----------------------------------------------------------------------------------------------|
| `--allow-read`        | `workingDirectory`, script dir, `migrationsPath`, Deno cache dir                             |
| `--allow-write`       | `workingDirectory` only                                                                      |
| `--allow-net`         | `jsr.io`, `registry.npmjs.org`, `esm.sh`                                                     |
| `--allow-ffi`         | unrestricted (Deno 2.x path-scoped FFI is broken for any real FFI package — see `CLAUDE.md`) |
| `--allow-env`         | `MIGRATIONS_DIR` + Node-compat probe vars (`READABLE_STREAM`, `BLUEBIRD_*`, `NODE_ENV`, …)   |
| `--allow-sys`         | denied                                                                                       |
| `--deny-run`          | always — no subprocess spawning from inside                                                  |
| `--lock … --frozen`   | always — points at `lockfile/deno.lock` bundled with the package                             |
| `--no-config`         | always — parent-directory `deno.json`/`deno.jsonc` auto-discovery is suppressed              |

`SandboxRequest.timeout` and `maxOutputBytes` enforce resource limits — exceeding either terminates the subprocess (tree-killed on Windows via `taskkill /F /T`) and marks the result with `TerminationReason.timedOut` or `outputCapExceeded`.

## Observing execution

Pass `onEvent` to receive the full `SandboxEvent` stream:

- `ProcessStartedEvent { pid }`
- `OutputChunkEvent { text, isStderr }`
- `PermissionViolationEvent { capability, detail }` — parsed from Deno's `NotCapable: …` errors
- `TimeoutEvent { elapsed }`
- `OutputCapEvent { bytesEmitted }`
- `ProcessExitedEvent { exitCode, reason }`

Example: log every permission violation separately.

```dart
final violations = <PermissionViolationEvent>[];
await QuiverSandbox().execute(SandboxRequest(
  scriptPath: ...,
  workingDirectory: ...,
  migrationsPath: ...,
  onEvent: (e) {
    if (e is PermissionViolationEvent) violations.add(e);
  },
));
for (final v in violations) {
  print('script tried to use ${v.capability}${v.detail.isEmpty ? "" : ": ${v.detail}"}');
}
```

## Allowing a new package

Scripts must resolve to specs pinned in the package's `lockfile/deno.lock`. To allow a new package:

```bash
# After adding `import … from "npm:newthing@1.2.3"` to a permit fixture:
dart run tool/add_package.dart

# Or pre-approve without a fixture (one-off):
dart run tool/add_package.dart npm:newthing@1.2.3
```

Commit the updated `lockfile/deno.lock`. The host app picks it up on next build.

For long-lived allowlist entries, also add a permit fixture that imports the package so it's exercised by the test suite — an unused lockfile entry is an un-verified allowlist entry.

## Testing

```bash
dart test                          # full suite (requires Deno)
dart test test/unit/               # pure Dart + minimal Deno probes
dart test test/integration/        # fixture-driven end-to-end
```

See `CLAUDE.md` for the architecture overview, fixture layout, and the full permission-model rationale.
