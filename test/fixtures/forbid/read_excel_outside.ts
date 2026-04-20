// Uses exceljs to read a workbook from a parent-traversal path — should be
// denied. Exercises a realistic npm-package file I/O path, not just raw
// Deno.readFile; the permission check fires before exceljs touches the file,
// regardless of whether the target exists.
import ExcelJS from "npm:exceljs@4.4.0";

const workbook = new ExcelJS.Workbook();
await workbook.xlsx.readFile("../escape.xlsx");
console.log("read should not succeed");
