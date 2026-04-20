// Tries to open an inbound TCP listener. --allow-net is scoped to specific
// outbound package hosts only, so binding to any local hostname is denied.
const listener = Deno.listen({ hostname: "127.0.0.1", port: 0 });
listener.close();
