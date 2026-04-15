// Generates an HTML file in the database directory.
const html = `<!DOCTYPE html>
<html>
<head><title>Test Report</title></head>
<body><h1>QuiverSandbox Report</h1><p>Generated successfully.</p></body>
</html>`;
await Deno.writeTextFile(`report.html`, html);
