// Writes a file inside databasePath — should be allowed.
await Deno.writeTextFile(`test_write.txt`, "db write ok");
