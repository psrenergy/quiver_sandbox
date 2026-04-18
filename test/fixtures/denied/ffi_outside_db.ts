// Tries to open a shared library — should be denied because FFI is disabled entirely.
Deno.dlopen("/usr/lib/libm.so", {});
