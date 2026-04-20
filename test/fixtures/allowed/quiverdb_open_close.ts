import { Database } from "jsr:@psrenergy/quiver@^0.7.4";

const MIGRATIONS = Deno.env.get("MIGRATIONS_DIR")!;

const db = Database.fromMigrations(`test.db`, MIGRATIONS);
db.close();
