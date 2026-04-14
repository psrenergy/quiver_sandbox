import { Database } from "npm:quiverdb@0.6.2";

const DB_DIR = Deno.args[0];
const MIGRATIONS = Deno.args[1];

const db = Database.fromMigrations(`${DB_DIR}/test.db`, MIGRATIONS);
console.log("database opened successfully");
db.close();
console.log("database closed successfully");
