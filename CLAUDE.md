# QuiverSandbox

Dart library that executes user-authored and AI-generated JS/TS scripts inside Deno's permission-scoped sandbox. Scripts access QuiverDB databases (`jsr:@psrenergy/quiver@^0.7.4`, a Deno-native package whose loader downloads its bundled native library into `{cwd}/.psrenergy-quiver-cache/` on first use).

**Design stance**: secure-by-default, permissive by opt-in. Built-in hardening covers the main threats a POC cares about: lockfile-enforced module allowlist, wall-clock timeout, output-size cap, scoped filesystem/network access, and structured events for every violation.

## Commands

- `dart pub get` — install dependencies
- `dart analyze` — static analysis
- `dart test` — run all tests (requires Deno)
- `dart test test/unit/` — pure-Dart and minimal-Deno unit tests
- `dart test test/integration/` — fixture-driven integration tests

## Architecture

Split by responsibility under `lib/src/`:

- `policy.dart` — `SandboxPolicy`: builds the Deno `--allow-*`/`--deny-*`/`--lock`/`--frozen`/`--no-lock` flag list. Pure, const-constructible, zero I/O.
- `request.dart` — `SandboxRequest`: single input object for `QuiverSandbox.execute`. Validates path-absoluteness and positive byte cap at construction.
- `result.dart` — `SandboxResult` and `TerminationReason` (enum: `completed`, `timedOut`, `outputCapExceeded`, `killed`, `startFailure`).
- `events.dart` — sealed `SandboxEvent` hierarchy: `OutputChunkEvent`, `ProcessStartedEvent`, `ProcessExitedEvent`, `PermissionViolationEvent`, `TimeoutEvent`, `OutputCapEvent`.
- `runner.dart` — `SandboxRunner.run`: `Process.start` + timeout + output cap + stderr-to-event parsing. On Windows uses `taskkill /F /T /PID` for tree-kill so that killing the shell wrapper also terminates the grandchild `deno.exe`.
- `deno_info.dart` — memoized `resolveDenoCacheDir` via `deno info --json`.

Public API barrel (`lib/quiver_sandbox.dart`) re-exports `SandboxPolicy`, `SandboxRequest`, `SandboxResult`, `TerminationReason`, the `SandboxEvent` family, and the `QuiverSandbox` class.

## Deno Permission Model

Defaults (configurable via `SandboxPolicy`):

- `--allow-read`: `workingDirectory`, scriptDir, `migrationsPath`, auto-detected Deno cache dir.
- `--allow-write`: `workingDirectory` only. The ephemeral temp dir is the only place a sandboxed script can write.
- `--allow-net`: `jsr.io`, `registry.npmjs.org`, `esm.sh`.
- `--allow-ffi`: unscoped. Deno 2.x path-scoped `--allow-ffi=X` only covers the `Deno.dlopen()` path check; `Deno.UnsafePointer.of()` and every other pointer op require unscoped FFI. Defense-in-depth comes from `--allow-write` restricting where a script can deposit a native library, not from path-scoped FFI.
- `--allow-env`: narrow allowlist. `MIGRATIONS_DIR` (we set it) plus Node-compat probe vars (`READABLE_STREAM`, `GRACEFUL_FS_PLATFORM`, `NODE_DEBUG`, `BLUEBIRD_*`, `NODE_ENV`, etc.) that common npm packages throw on if missing.
- `--allow-sys`: off by default. Opt-in via `SandboxPolicy(allowSys: true)`.
- `--lock=<path> --frozen`: emitted when `SandboxPolicy.lockfilePath` is set and `allowArbitraryPackages` is false (the default). Any import not pinned in the lockfile fails. With `allowArbitraryPackages: true`, `--no-lock` is emitted instead.

Denied:
- `--deny-run` — no subprocess spawning.

## Resource limits

`SandboxRequest` exposes two limits enforced by the runner:
- `timeout` (default 30s): wall-clock limit. On expiry, the runner kills the tree and reports `TerminationReason.timedOut` via `TimeoutEvent`.
- `maxOutputBytes` (default 10 MB): combined stdout+stderr. On overflow, the runner kills the tree and reports `TerminationReason.outputCapExceeded` via `OutputCapEvent`.

## Testing layout

- `test/fixtures/permit/` — scripts that must exit 0 under the default policy + project lockfile. Covers minimal sandbox surface: `empty_script`, `hello`, `write_file`, `generate_json`, `import_local_module`, `quiverdb_open_close`, plus `_helper.ts` (not run directly).
- `test/fixtures/forbid/` — scripts that must exit non-zero. Covers every denial path: env read/write, net, read outside sandbox, path traversal, subprocess, FFI outside allowed, npm install-script, `--allow-sys` denied, syntax error, runtime error.
- `test/fixtures/limits/` — scripts that exceed limits: `infinite_loop.ts` (blows `timeout`), `output_flood.ts` (blows `maxOutputBytes`).
- `test/fixtures/lockfile/` — `untrusted_import.ts` (`npm:left-pad@1.3.0`) — fails under `--frozen`, succeeds under `allowArbitraryPackages: true`.
- `test/data/deno.lock` — committed lockfile for the permit fixtures. Regenerate with `deno cache --lock=test/data/deno.lock --frozen=false test/fixtures/permit/quiverdb_open_close.ts`.
- `test/data/migrations/` — fixtures consumed by `quiverdb_open_close.ts`.
- `test/unit/` — pure-Dart `policy_test.dart`, plus `runner_test.dart` (uses Deno for minimal probes).
- `test/integration/` — harness + `permit_test.dart`, `forbid_test.dart`, `limits_test.dart`, `lockfile_test.dart`.

`sandbox_harness.dart` discovers `.ts` fixtures in a folder and runs each through `QuiverSandbox.execute`, exposing the result + output + event list to a `verify` callback.

## Platform notes

- `Process.start` uses `runInShell: Platform.isWindows` for invocation (Deno resolution through PATHEXT) and `taskkill /F /T /PID` for kills (the shell wrapper orphans its child otherwise).
