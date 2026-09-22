import fs from "node:fs";
import { seeds } from "../web/lib/templates.mjs";
fs.writeFileSync(
  new URL("../Branch/BranchSeeds.json", import.meta.url),
  JSON.stringify(seeds, null, 2),
);
console.log("Updated the bundled iOS starter library.");
