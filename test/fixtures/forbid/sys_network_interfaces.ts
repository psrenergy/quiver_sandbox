// Enumerates local network interfaces — denied by the omitted --allow-sys.
// Complements sys_info.ts (hostname probe) to cover a second sys capability.
const interfaces = Deno.networkInterfaces();
console.log(`count: ${interfaces.length}`);
