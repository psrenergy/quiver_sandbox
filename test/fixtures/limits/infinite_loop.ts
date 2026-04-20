// Runs forever. The sandbox should kill this on [SandboxRequest.timeout].
while (true) {
  await new Promise((r) => setTimeout(r, 100));
}
