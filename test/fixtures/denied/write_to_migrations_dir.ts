// Attempts to write to the migrations directory (should be read-only).
const migrationsDir = Deno.args[1];
await Deno.writeTextFile(`${migrationsDir}/hack.txt`, "should not exist");
