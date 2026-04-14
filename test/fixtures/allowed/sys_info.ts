// Reads system info — allowed by --allow-sys.
const hostname = Deno.hostname();
console.log(`hostname: ${hostname}`);
