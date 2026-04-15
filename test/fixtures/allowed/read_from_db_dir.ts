// Reads a file from the database directory — allowed by --allow-read.
await Deno.writeTextFile("read_test.txt", "hello");
const content = await Deno.readTextFile("read_test.txt");
console.log(content);
