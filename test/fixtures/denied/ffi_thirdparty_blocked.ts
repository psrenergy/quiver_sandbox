// Tries to import better-sqlite3, which uses native FFI bindings.
// Fails because FFI is scoped to the sandbox's allowlisted packages only.
import Database from "npm:better-sqlite3@11.9.1";

const db = new Database(":memory:");
console.log("better-sqlite3 loaded successfully");
db.close();
