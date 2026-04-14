// Tries to read system info — should be denied by --deny-sys.
const hostname = Deno.hostname();
console.log(`hostname: ${hostname}`);
