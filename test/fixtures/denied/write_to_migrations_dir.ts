// Attempts to write to the migrations directory (should be read-only).
const migrationsDir = Deno.env.get("MIGRATIONS_DIR")!;

await Deno.writeTextFile(`${migrationsDir}/hack.txt`, "should not exist");
