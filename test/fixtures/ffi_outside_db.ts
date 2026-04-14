// Tries to open a shared library from outside the allowed databasePath — should be denied.
Deno.dlopen("/usr/lib/libm.so", {});
