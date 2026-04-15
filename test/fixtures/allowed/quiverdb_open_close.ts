import { Database } from "npm:quiverdb@0.6.2";

const MIGRATIONS = Deno.env.get("MIGRATIONS_DIR")!;

const db = Database.fromMigrations(`test.db`, MIGRATIONS);
db.close();
