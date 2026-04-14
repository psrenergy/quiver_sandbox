// Writes a test file to the output directory passed as the first argument.
const outputDir = Deno.args[0];
const filePath = `${outputDir}/test_output.txt`;
await Deno.writeTextFile(filePath, "hello from sandbox");
console.log(`wrote: ${filePath}`);
