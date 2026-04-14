// Tries to read system info — should be denied by --deny-sys.
try {
  const hostname = Deno.hostname();
  console.log(`hostname: ${hostname}`);
} catch (e) {
  console.error(e);
  Deno.exit(1);
}
