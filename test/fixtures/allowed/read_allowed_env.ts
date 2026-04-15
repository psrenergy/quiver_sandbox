// Reads an allowed environment variable — MIGRATIONS_DIR is in the allowlist.
const dir = Deno.env.get("MIGRATIONS_DIR");
console.log(`MIGRATIONS_DIR: ${dir}`);
