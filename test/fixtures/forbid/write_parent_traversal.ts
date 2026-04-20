// Tries to write outside the database directory via traversal — should be denied.
await Deno.writeTextFile("../escape_write.txt", "should not exist");
