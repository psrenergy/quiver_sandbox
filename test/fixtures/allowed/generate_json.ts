// Writes a JSON file to the database directory.
const data = { status: "ok", items: [1, 2, 3], generated: true };
await Deno.writeTextFile(`data.json`, JSON.stringify(data, null, 2));
