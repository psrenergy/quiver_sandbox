// Deno.makeTempFile() writes to the OS temp directory, not into the sandbox
// workingDirectory. That path is outside --allow-write and must be denied —
// otherwise a script could drop arbitrary files in a shared /tmp or %TEMP%.
const path = await Deno.makeTempFile({ prefix: "qsb_escape_" });
console.log(`created at ${path}`);
