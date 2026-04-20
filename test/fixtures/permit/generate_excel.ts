// Generates an Excel file in the workingDirectory using exceljs.
// Exercises npm-hosted packages with native Node-compat probes (readable-stream,
// graceful-fs, bluebird) — all covered by SandboxPolicy.allowedEnv.
import ExcelJS from "npm:exceljs@4.4.0";

const workbook = new ExcelJS.Workbook();
const sheet = workbook.addWorksheet("Data");
sheet.columns = [
  { header: "Name", key: "name" },
  { header: "Value", key: "value" },
];
sheet.addRow({ name: "test", value: 42 });
await workbook.xlsx.writeFile(`report.xlsx`);
console.log("excel generated");
