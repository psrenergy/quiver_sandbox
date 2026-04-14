// Tries to read an environment variable — should be denied by --deny-env.
const path = Deno.env.get("PATH");
console.log(`PATH: ${path}`);
