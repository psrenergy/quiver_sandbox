// Generates a PDF file in the workingDirectory using pdf-lib.
import { PDFDocument } from "npm:pdf-lib@1.17.1";

const doc = await PDFDocument.create();
const page = doc.addPage();
page.drawText("Hello from sandbox");
const bytes = await doc.save();
await Deno.writeFile("report.pdf", bytes);
console.log("pdf generated");
