// Generates an Excel file in outputDir (first arg) using exceljs.
import ExcelJS from "npm:exceljs@4.4.0";

const outputDir = Deno.args[0];
const workbook = new ExcelJS.Workbook();
const sheet = workbook.addWorksheet("Data");
sheet.columns = [
  { header: "Name", key: "name" },
  { header: "Value", key: "value" },
];
sheet.addRow({ name: "test", value: 42 });
await workbook.xlsx.writeFile(`${outputDir}/report.xlsx`);
console.log("excel generated");
