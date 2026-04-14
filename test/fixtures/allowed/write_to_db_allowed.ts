// Writes a file inside databasePath (first arg) — should be allowed.
const dbDir = Deno.args[0];
await Deno.writeTextFile(`${dbDir}/test_write.txt`, "db write ok");
console.log("wrote to databasePath");
