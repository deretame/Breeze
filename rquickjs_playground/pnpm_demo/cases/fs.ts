export default async function main(config: unknown = {}) {
  const cfg = (config || {}) as { baseDir?: string };
  const base = String(cfg.baseDir || ".");
  const runtimeFs = (globalThis as unknown as {
    fs?: {
      promises?: {
        writeFile: (path: string, data: string | Uint8Array, options?: string) => Promise<void>;
        appendFile: (path: string, data: string | Uint8Array, options?: string) => Promise<void>;
        readFile: (path: string, options?: string) => Promise<string | Uint8Array>;
        rm: (path: string, options?: { force?: boolean; recursive?: boolean }) => Promise<void>;
      };
    };
  }).fs;
  if (!runtimeFs || !runtimeFs.promises) {
    return { ok: false, reason: "runtime-fs-missing" };
  }
  const file = `${base.replace(/\\/g, "/")}/case.txt`;

  await runtimeFs.promises.writeFile(file, "hello", "utf8");
  await runtimeFs.promises.appendFile(file, "-world", "utf8");
  const text = await runtimeFs.promises.readFile(file, "utf8") as string;
  await runtimeFs.promises.rm(file, { force: true });
  return { ok: text === "hello-world" };
}
