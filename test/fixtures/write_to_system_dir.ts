// Tries to write to a system directory — should be denied.
await Deno.writeTextFile("/tmp/quiver_sandbox_hack.txt", "should not exist");
