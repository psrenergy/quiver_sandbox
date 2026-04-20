// Writes an HTML report to the workingDirectory using only Deno built-ins.
const html = `<!DOCTYPE html>
<html>
<head><title>Test Report</title></head>
<body><h1>QuiverSandbox Report</h1><p>Generated successfully.</p></body>
</html>`;
await Deno.writeTextFile(`report.html`, html);
