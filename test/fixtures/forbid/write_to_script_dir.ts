// Tries to write a file in the script's own directory — should be denied.
const scriptDir = new URL(".", import.meta.url).pathname;
await Deno.writeTextFile(`${scriptDir}/hack.txt`, "should not exist");
