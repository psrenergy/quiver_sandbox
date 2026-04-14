# QuiverSandbox

Dart library that executes user-authored and AI-generated JS/TS scripts inside Deno's permission-scoped sandbox. Scripts access QuiverDB databases (`npm:quiverdb@0.6.2`, which uses Koffi FFI for SQLite) and generate HTML dashboards, PDF reports, and Excel files.

## Commands

- `dart pub get` — install dependencies
- `dart analyze` — static analysis
- `dart test` — run all tests (unit + integration, requires Deno)
- `dart test test/sandbox_config_test.dart` — unit tests only (no Deno required)
- `dart test test/integration/` — integration tests only (requires Deno)

## Architecture

- `lib/src/sandbox_config.dart` — `SandboxConfig`: all inputs (scriptPath, databasePath, outputDir, args, permissions)
- `lib/src/permission_builder.dart` — `PermissionBuilder`: assembles Deno `--allow-*`/`--deny-*` flags from config
- `lib/src/deno_runner.dart` — `QuiverSandbox`: executes scripts via `Process.start`, streams output to `writeInTerminal` callback, returns exit code; auto-detects Deno cache dir

## Deno Permission Model

### Allowed (scoped)
- `--allow-read`: databasePath, scriptDir, migrationsPath, denoCacheDir
- `--allow-write`: databasePath, outputDir
- `--allow-net`: npm registries (registry.npmjs.org, esm.sh) by default
- `--allow-ffi`: databasePath, denoCacheDir (Koffi native binaries)

### Denied
- `--deny-run`: always (no subprocess spawning)
- `--deny-sys`: by default (toggle via `allowSys: true` if Koffi needs OS/arch info)

## Testing

- Unit tests validate flag assembly and config defaults without Deno
- Integration tests (`test/integration/`) run real Deno scripts from `test/fixtures/` to verify each permission is enforced
- QuiverDB integration test uses migrations from `test/data/migrations/` to open and close a real database
- Deno 2.x uses `NotCapable` (not `PermissionDenied`) in error messages
- On Windows, `Process.run` needs `runInShell: true` and fixtures must use real executables (not shell builtins like `echo`)
