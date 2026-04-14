// Reads an environment variable — allowed by --allow-env.
const path = Deno.env.get("PATH");
console.log(`PATH: ${path}`);
