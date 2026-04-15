// Produces large output to test streaming — allowed.
for (let i = 0; i < 10000; i++) {
  console.log(`line ${i}: ${"x".repeat(100)}`);
}
