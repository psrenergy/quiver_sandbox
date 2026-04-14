// Tries to fetch a non-allowed host — should be denied.
try {
  const resp = await fetch("https://example.com");
  console.log(`status: ${resp.status}`);
} catch (e) {
  console.error(e);
  Deno.exit(1);
}
