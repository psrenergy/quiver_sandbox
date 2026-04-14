// Writes a JSON file to outputDir (first arg).
const outputDir = Deno.args[0];
const data = { status: "ok", items: [1, 2, 3], generated: true };
await Deno.writeTextFile(`${outputDir}/data.json`, JSON.stringify(data, null, 2));
console.log("json generated");
