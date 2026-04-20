# QuiverSandbox

Dart library that executes user-authored and AI-generated JS/TS scripts inside Deno's permission-scoped sandbox. Scripts access QuiverDB databases (`jsr:@psrenergy/quiver@^0.7.4`, a Deno-native package whose loader downloads its bundled native library into `{cwd}/.psrenergy-quiver-cache/` on first use) and generate HTML dashboards, PDF reports, and Excel files.

## Commands

- `dart pub get` — install dependencies
- `dart analyze` — static analysis
- `dart test` — run all tests (requires Deno)
- `dart test test/integration/` — integration tests only (requires Deno)

## Architecture

- `lib/quiver_sandbox.dart` — single source file containing:
  - `PermissionBuilder`: assembles Deno `--allow-*`/`--deny-*` flags; validates all paths are absolute
  - `QuiverSandbox`: executes scripts via `Process.start`, streams output to `writeInTerminal` callback, returns exit code; auto-detects Deno cache dir via `deno info --json`

## Deno Permission Model

### Allowed (scoped)
- `--allow-read`: databasePath, scriptDir, migrationsPath, denoCacheDir (auto-detected)
- `--allow-write`: databasePath
- `--allow-net`: registry.npmjs.org, esm.sh, jsr.io
- `--allow-ffi`: unscoped. Deno 2.x path-scoped `--allow-ffi=X` only covers `Deno.dlopen()` path checks; `Deno.UnsafePointer.of()` and related pointer ops — which every real FFI package uses — require unscoped FFI. The quiver loader caches its native library at `{databasePath}/.psrenergy-quiver-cache/libs/{platform}/` on first use; defense-in-depth against arbitrary-DLL loading comes from `--allow-read`/`--allow-write` restricting where user scripts can place files.
- `--allow-env`: MIGRATIONS_DIR plus Node-compat vars (READABLE_STREAM, GRACEFUL_FS_PLATFORM, TEST_GRACEFUL_FS_GLOBAL_PATCH, NODE_DEBUG, NODE_ENV, BLUEBIRD_*) probed by npm packages
- `--allow-sys`: always

### Denied
- `--deny-run`: no subprocess spawning

## Testing

- Integration tests (`test/integration/`) run real Deno scripts from `test/fixtures/` to verify each permission is enforced
- `sandbox_harness.dart` dynamically discovers `.ts` fixtures and runs each through `QuiverSandbox.execute()`
- `test/fixtures/allowed/` — 15 scripts that must exit 0 (e.g., QuiverDB open/close, file generation, PDF/Excel output, env var reads, local imports, sys info)
- `test/fixtures/denied/` — 14 scripts that must exit non-zero (e.g., read outside sandbox, path traversal, env writes, net access, subprocess spawning)
- QuiverDB integration test uses migrations from `test/data/migrations/` to open and close a real database
- On Windows, `Process.start` needs `runInShell: true`
