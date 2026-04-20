// Tries to escape the sandbox by traversing to the parent directory — should be denied.
const content = await Deno.readTextFile("../escape_test.txt");
console.log(content);
