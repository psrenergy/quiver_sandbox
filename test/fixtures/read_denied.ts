// Tries to read from the system root — should be denied.
const content = await Deno.readTextFile("/etc/passwd");
console.log(content);
