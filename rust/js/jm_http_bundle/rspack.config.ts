import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { createRspackConfig } from "./rspack.shared";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const config = createRspackConfig({
  rootDir: __dirname,
  outPath: resolve(__dirname, "../../src/js"),
  outFileName: "jm_http.bundle.cjs",
});

export default config;
