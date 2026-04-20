// Emits stdout as fast as it can. The sandbox should kill this once
// [SandboxRequest.maxOutputBytes] is exceeded.
const chunk = "x".repeat(1024);
while (true) {
  console.log(chunk);
}
