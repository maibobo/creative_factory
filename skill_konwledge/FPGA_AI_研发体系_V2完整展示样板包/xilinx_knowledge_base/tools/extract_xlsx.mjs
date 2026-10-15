import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) {
  throw new Error("usage: extract_xlsx.mjs <input.xlsx> <output.ndjson>");
}

const blob = await FileBlob.load(inputPath);
const workbook = await SpreadsheetFile.importXlsx(blob);
const inspected = await workbook.inspect({
  kind: "workbook,sheet,table",
  maxChars: 4000000,
  tableMaxRows: 1000,
  tableMaxCols: 80,
  tableMaxCellChars: 500,
});
await fs.writeFile(outputPath, inspected.ndjson, "utf8");

