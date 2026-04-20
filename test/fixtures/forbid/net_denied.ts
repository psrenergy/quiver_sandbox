// Tries to fetch a non-allowed host — should be denied.
const resp = await fetch("https://example.com");
console.log(`status: ${resp.status}`);
