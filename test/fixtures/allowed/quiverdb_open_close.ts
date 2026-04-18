import { Database } from "jsr:@psrenergy/quiver";

const MIGRATIONS = Deno.env.get("MIGRATIONS_DIR")!;

const db = Database.fromMigrations(`test.db`, MIGRATIONS);
db.close();
