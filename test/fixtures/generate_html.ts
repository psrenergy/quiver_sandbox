// Generates an HTML file in outputDir (first arg).
const outputDir = Deno.args[0];
const html = `<!DOCTYPE html>
<html>
<head><title>Test Report</title></head>
<body><h1>QuiverSandbox Report</h1><p>Generated successfully.</p></body>
</html>`;
await Deno.writeTextFile(`${outputDir}/report.html`, html);
console.log("html generated");
