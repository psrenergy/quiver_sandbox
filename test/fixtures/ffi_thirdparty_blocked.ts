// Tries to import better-sqlite3, which uses native FFI bindings.
// Should fail with NotCapable when FFI scope excludes the Deno cache.
import Database from "npm:better-sqlite3@11.9.1";

try {
  const db = new Database(":memory:");
  console.log("better-sqlite3 loaded successfully");
  db.close();
} catch (e) {
  console.error(e);
  Deno.exit(1);
}
