// Tries to import better-sqlite3 from npm — fails because --allow-net is scoped
// to jsr.io only, and FFI is denied regardless.
import Database from "npm:better-sqlite3@11.9.1";

const db = new Database(":memory:");
console.log("better-sqlite3 loaded successfully");
db.close();
