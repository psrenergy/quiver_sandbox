// Tries to set an environment variable — should be denied.
Deno.env.set("MALICIOUS_VAR", "injected");
