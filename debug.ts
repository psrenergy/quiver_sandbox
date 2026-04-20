import { Database } from "jsr:@psrenergy/quiver";
Database.fromMigrations("t.db", "./migrations").close();