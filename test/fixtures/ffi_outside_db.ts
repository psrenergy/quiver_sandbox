// Tries to open a shared library from outside the allowed databasePath — should be denied.
try {
  Deno.dlopen("/usr/lib/libm.so", {});
} catch (e) {
  console.error(e);
  Deno.exit(1);
}
