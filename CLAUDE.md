# QuiverSandbox

**Internal component extracted as a Dart package for test isolation.** Not a public library, not intended for distribution. The host app depends on it directly; this repo exists so the sandbox behavior can be tested without spinning up the whole app.

Executes JS/TS scripts inside Deno's permission-scoped sandbox. Scripts access QuiverDB databases (`jsr:@psrenergy/quiver@^0.7.4`, a Deno-native package whose loader downloads its bundled native library into `{cwd}/.psrenergy-quiver-cache/` on first use).

**Design stance**: the security profile is **fixed inside this package**. There is no policy knob on the public API — `QuiverSandbox.execute` always enforces the same flags, the same lockfile, the same resource limits. Tweaking the profile means editing this package, not the host app. Rationale: this is a single-tenant internal component with exactly one consumer; a configurable policy would be dead weight and an attack surface.

## Commands

- `dart pub get` — install dependencies
- `dart analyze` — static analysis
- `dart test` — run all tests (requires Deno)
- `dart test test/unit/` — pure-Dart and minimal-Deno unit tests
- `dart test test/integration/` — fixture-driven integration tests

## Architecture

Split by responsibility under `lib/src/`:

- `policy.dart` — `SandboxPolicy`: internal helper that assembles the Deno `--allow-*`/`--deny-*`/`--lock`/`--frozen`/`--no-config` flag list from a lockfile path. Not exported from the barrel.
- `request.dart` — `SandboxRequest`: single input object for `QuiverSandbox.execute`. Validates path-absoluteness and positive byte cap at construction. Has no `policy` field — the fixed policy is enforced regardless.
- `result.dart` — `SandboxResult` and `TerminationReason` (enum: `completed`, `timedOut`, `outputCapExceeded`, `killed`, `startFailure`).
- `events.dart` — sealed `SandboxEvent` hierarchy: `OutputChunkEvent`, `ProcessStartedEvent`, `ProcessExitedEvent`, `PermissionViolationEvent`, `TimeoutEvent`, `OutputCapEvent`.
- `runner.dart` — `SandboxRunner.run`: `Process.start` + timeout + output cap + stderr-to-event parsing. On Windows uses `taskkill /F /T /PID` for tree-kill so killing the shell wrapper also terminates the grandchild `deno.exe`.
- `deno_info.dart` — memoized `resolveDenoCacheDir` via `deno info --json`.
- `bundled_lockfile.dart` — resolves the absolute path of `lockfile/deno.lock` via `Isolate.resolvePackageUri`. `QuiverSandbox.execute` calls it internally to feed the policy.

Barrel (`lib/quiver_sandbox.dart`) exports only `QuiverSandbox`, `SandboxRequest`, `SandboxResult`, `TerminationReason`, and the `SandboxEvent` family. `SandboxPolicy` is deliberately **not** re-exported.

The host app depends on this package via local path (`dependencies: { quiver_sandbox: { path: ../quiver_sandbox } }` or similar) and uses the default `QuiverSandbox()` constructor — no policy to wire, no lockfile to resolve.

## Fixed Deno permission model

Emitted on every `execute` call, not configurable from outside the package:

- `--no-config` — always. Suppresses discovery of `deno.json`/`deno.jsonc` in parent directories; without this, Deno walks up from `workingDirectory` until it hits user-home or drive root and can find unrelated workspace configs that contradict our lockfile.
- `--allow-read`: `workingDirectory`, scriptDir, `migrationsPath`, auto-detected Deno cache dir.
- `--allow-write`: `workingDirectory` only. The ephemeral temp dir is the only place a sandboxed script can write.
- `--allow-net`: `jsr.io`, `registry.npmjs.org`, `esm.sh`.
- `--allow-ffi`: unscoped. Deno 2.x path-scoped `--allow-ffi=X` only covers the `Deno.dlopen()` path check; `Deno.UnsafePointer.of()` and every other pointer op require unscoped FFI. Defense-in-depth comes from `--allow-write` restricting where a script can deposit a native library, not from path-scoped FFI.
- `--allow-env`: narrow allowlist. `MIGRATIONS_DIR` (we set it) plus Node-compat probe vars (`READABLE_STREAM`, `GRACEFUL_FS_PLATFORM`, `NODE_DEBUG`, `BLUEBIRD_*`, `NODE_ENV`, etc.) that common npm packages throw on if missing.
- `--allow-sys`: denied. No `Deno.hostname`, `Deno.networkInterfaces`, etc.
- `--lock=lockfile/deno.lock --frozen`: always. Any import not pinned in the lockfile fails at module resolution.
- `--deny-run`: always. No subprocess spawning.

## Resource limits

`SandboxRequest` exposes two per-call limits enforced by the runner:
- `timeout` (default 30s): wall-clock limit. On expiry, the runner kills the tree and reports `TerminationReason.timedOut` via `TimeoutEvent`.
- `maxOutputBytes` (default 10 MB): combined stdout+stderr. On overflow, the runner kills the tree and reports `TerminationReason.outputCapExceeded` via `OutputCapEvent`.

These are per-call, not policy-level, because the host app legitimately needs to vary them (a quick report may have a 5s budget; a batch ingest may need 5min).

## Lockfile

A single canonical lockfile lives at **`lockfile/deno.lock`** at the package root. It covers every import used by the permit fixtures and is the *only* allowlist the host app ever consumes. There is exactly one consumer, so a single source of truth is simpler than splitting test and prod.

Regenerate with the dev tool:

```
# After editing a permit fixture (e.g. added `import "npm:newthing"`):
dart run tool/add_package.dart

# Pre-approve a spec without writing a fixture yet:
dart run tool/add_package.dart npm:dayjs@1.11.10 jsr:@std/cli@^1.0.0
```

The tool globs `test/fixtures/permit/*.ts` (non-underscore), optionally adds specs via a temp import file, deletes and rewrites `lockfile/deno.lock` from that full input set (Deno's `--frozen=false` only appends — explicit delete-then-regenerate prunes stale entries). Commit the updated lockfile.

For long-lived allowlist entries, **also add a permit fixture that imports the package** so it's exercised by the test suite — an unused lockfile entry is an un-verified allowlist entry.

**Known caveat**: the internal resolver uses `Isolate.resolvePackageUri`, which works for `dart run`, `dart test`, and `path:` deps but not AOT snapshots. Production distribution of the host app as a compiled binary would need a different asset-bundling strategy — out of scope for the current POC.

## Testing layout

- `test/fixtures/permit/` — scripts that must exit 0 under the fixed policy. Realistic sandbox surface: `empty_script`, `hello`, `write_file`, `generate_json`, `generate_html`, `generate_excel` (uses `npm:exceljs`), `generate_pdf` (uses `npm:pdf-lib`), `import_local_module`, `quiverdb_open_close`, plus `_helper.ts` (not run directly).
- `test/fixtures/forbid/` — scripts that must exit non-zero. Every denial path: env read/write, net, read outside sandbox, path traversal, subprocess, FFI outside allowed, npm install-script, `--allow-sys` denied, syntax error, runtime error.
- `test/fixtures/limits/` — scripts that exceed limits: `infinite_loop.ts` (blows `timeout`), `output_flood.ts` (blows `maxOutputBytes`).
- `test/fixtures/lockfile/` — `untrusted_import.ts` (`npm:left-pad@1.3.0`) — fails under the fixed `--frozen` policy.
- `test/data/migrations/` — fixtures consumed by `quiverdb_open_close.ts`.
- `test/unit/` — pure-Dart `policy_test.dart` (imports `package:quiver_sandbox/src/policy.dart` directly since `SandboxPolicy` isn't in the public barrel) plus `runner_test.dart` (needs Deno for minimal probes).
- `test/integration/` — harness + `permit_test.dart`, `forbid_test.dart`, `limits_test.dart`, `lockfile_test.dart`.

`sandbox_harness.dart` discovers `.ts` fixtures in a folder and runs each through `QuiverSandbox.execute`, exposing the result + output + event list to a `verify` callback.

## Platform notes

- `Process.start` uses `runInShell: Platform.isWindows` for invocation (Deno resolution through PATHEXT) and `taskkill /F /T /PID` for kills (the shell wrapper orphans its child otherwise).
