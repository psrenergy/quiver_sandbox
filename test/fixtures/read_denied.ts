// Tries to read from the system root — should be denied.
try {
  const content = await Deno.readTextFile("/etc/passwd");
  console.log(content);
} catch (e) {
  console.error(e);
  Deno.exit(1);
}
