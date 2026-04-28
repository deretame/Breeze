import { build } from "esbuild";
import { mkdir, rm } from "node:fs/promises";

const caseNames = ["fetch", "axios", "fs", "native", "runtime", "runtime_api", "wasi", "bridge"];

await rm("dist/cases", { recursive: true, force: true });
await mkdir("dist/cases", { recursive: true });

for (const name of caseNames) {
  await build({
    entryPoints: [`cases/${name}.ts`],
    outfile: `dist/cases/${name}.js`,
    bundle: true,
    packages: "bundle",
    platform: "browser",
    format: "cjs",
    target: "es2020",
    treeShaking: true,
    legalComments: "none",
    sourcemap: false,
    minify: true,
  });
}
