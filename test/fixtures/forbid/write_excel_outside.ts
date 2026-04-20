// Uses exceljs to write a workbook to a parent-traversal path — should be
// denied. Same surface as write_parent_traversal.ts but through an npm
// package's internal file I/O, verifying the policy holds regardless of
// which Node/Deno API the write is routed through.
import ExcelJS from "npm:exceljs@4.4.0";

const workbook = new ExcelJS.Workbook();
workbook.addWorksheet("Data").addRow(["should not escape"]);
await workbook.xlsx.writeFile("../escape.xlsx");
