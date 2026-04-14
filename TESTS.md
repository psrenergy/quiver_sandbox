# Test Registry

Total: 31 tests (21 unit + 8 integration + 1 QuiverDB integration + 1 third-party FFI)

## Unit Tests (no Deno required)

### `test/quiver_sandbox_test.dart` — QuiverSandbox class

| # | Test | Verifies |
|---|------|----------|
| 1 | uses "deno" as default executable | Default `denoExecutable` is `"deno"` |
| 2 | accepts a custom executable path | Constructor stores custom path |

### `test/sandbox_config_test.dart` — SandboxConfig class (internal)

| # | Test | Verifies |
|---|------|----------|
| 3 | stores required fields | scriptPath, databasePath, outputDir are stored correctly |
| 4 | args defaults to empty list | Default `args` is `[]` |
| 5 | allowedNetHosts defaults to npm registries | Default is `['registry.npmjs.org', 'esm.sh']` |
| 6 | allowSys defaults to false | Default `allowSys` is `false` |
| 7 | timeout defaults to null | Default `timeout` is `null` |
| 8 | accepts custom values for all optional fields | All optional fields accept overrides |

### `test/permission_builder_test.dart` — PermissionBuilder class (internal)

| # | Test | Verifies |
|---|------|----------|
| 9 | --allow-read scoped to databasePath and script dir | Read scope = `databasePath,scriptDir` |
| 10 | --allow-write scoped to databasePath and outputDir | Write scope = `databasePath,outputDir` (QuiverDB writes .db files) |
| 11 | --allow-net scoped to default npm registries | Net scope = `registry.npmjs.org,esm.sh` |
| 12 | --allow-ffi scoped to databasePath | FFI scope = `databasePath` (Koffi native bindings) |
| 13 | --deny-run always | `--deny-run` is always present |
| 14 | --deny-sys by default | `--deny-sys` present when `allowSys` is false |
| 15 | --allow-sys when allowSys is true | `--allow-sys` present, `--deny-sys` absent |
| 16 | uses custom allowedNetHosts | Custom hosts override defaults |
| 17 | throws ArgumentError for relative scriptPath | Rejects non-absolute script paths |
| 18 | throws ArgumentError for relative databasePath | Rejects non-absolute database paths |
| 19 | throws ArgumentError for relative outputDir | Rejects non-absolute output paths |
| 20 | includes additionalReadPaths in --allow-read | Extra paths appended to read scope |
| 21 | throws ArgumentError for relative additionalReadPaths | Rejects non-absolute additional paths |

## Integration Tests (requires Deno)

### `test/integration/sandbox_test.dart` — Allowed operations

| # | Test | Fixture | Verifies |
|---|------|---------|----------|
| 22 | script receives positional args | `hello.ts` | Args forwarded to Deno script, echoed as JSON |
| 23 | script can write to outputDir | `write_file.ts` | Script creates file in outputDir, content matches |

### `test/integration/sandbox_test.dart` — Denied operations

| # | Test | Fixture | Verifies |
|---|------|---------|----------|
| 24 | CANNOT read outside allowed dirs | `read_denied.ts` | Reading `/etc/passwd` fails with `NotCapable` |
| 25 | CANNOT spawn subprocesses | `run_denied.ts` | Running `deno --version` as subprocess fails with `NotCapable` |
| 26 | CANNOT load FFI outside databasePath | `ffi_outside_db.ts` | Loading `/usr/lib/libm.so` fails with `NotCapable` |
| 27 | CANNOT fetch non-allowed hosts | `net_denied.ts` | Fetching `https://example.com` fails with `NotCapable` |

### `test/integration/sandbox_test.dart` — --deny-sys toggle

| # | Test | Fixture | Verifies |
|---|------|---------|----------|
| 28 | CANNOT access sys info with allowSys=false | `sys_denied.ts` | `Deno.hostname()` fails with `NotCapable` |
| 29 | CAN access sys info with allowSys=true | `sys_denied.ts` | `Deno.hostname()` succeeds, output contains hostname |

### `test/integration/sandbox_test.dart` — QuiverDB operations

| # | Test | Fixture | Verifies |
|---|------|---------|----------|
| 30 | script can open and close QuiverDB database | `quiverdb_open_close.ts` | Imports `npm:quiverdb@0.6.2`, runs `Database.fromMigrations()` with real migrations from `test/data/migrations/`, opens and closes DB successfully |

### `test/integration/sandbox_test.dart` — Third-party FFI restriction

| # | Test | Fixture | Verifies |
|---|------|---------|----------|
| 31 | third-party FFI package is blocked without Deno cache in FFI scope | `ffi_thirdparty_blocked.ts` | Imports `npm:better-sqlite3@11.9.1` (native FFI bindings). Grants `--allow-read` to Deno cache (so npm import resolves) but excludes it from `--allow-ffi` scope. Native binary load fails with `NotCapable`. |

## Test Fixtures

| File | Purpose |
|------|---------|
| `test/fixtures/hello.ts` | Prints `Deno.args` as JSON to stdout |
| `test/fixtures/write_file.ts` | Writes "hello from sandbox" to `<outputDir>/test_output.txt` |
| `test/fixtures/read_denied.ts` | Attempts to read `/etc/passwd` (should be denied) |
| `test/fixtures/run_denied.ts` | Attempts to spawn `deno --version` subprocess (should be denied) |
| `test/fixtures/ffi_outside_db.ts` | Attempts to `dlopen` `/usr/lib/libm.so` (should be denied) |
| `test/fixtures/sys_denied.ts` | Attempts to call `Deno.hostname()` (denied/allowed based on config) |
| `test/fixtures/net_denied.ts` | Attempts to fetch `https://example.com` (should be denied) |
| `test/fixtures/quiverdb_open_close.ts` | Opens QuiverDB via `Database.fromMigrations()`, logs success, closes |
| `test/fixtures/ffi_thirdparty_blocked.ts` | Imports `npm:better-sqlite3@11.9.1`, attempts to open in-memory DB (should be denied FFI) |

## Test Data

| Path | Purpose |
|------|---------|
| `test/data/migrations/1..19/` | QuiverDB SQL migration files (up.sql/down.sql) with tables: Configuration, Material, Recipe, Process, Plant, InputMarket, OutputMarket, Storage, ProcessInPlant |
