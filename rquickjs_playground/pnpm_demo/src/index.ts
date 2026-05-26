export default async function main() {
  const pathApi = (globalThis as unknown as { path?: { join?: (...parts: string[]) => string } }).path;
  const joinPath = pathApi && typeof pathApi.join === "function"
    ? (...parts: string[]) => pathApi.join!(...parts)
    : (...parts: string[]) => parts.join("/").replace(/\/+/g, "/").replace("/images/../", "/");
  const joined = joinPath("/demo", "images", "..", "out.png");

  if (!globalThis.native) {
    return {
      ok: true,
      runtime: "node",
      joined,
      note: "native 不存在，走 Node 回退路径",
    };
  }

  const input = new Uint8Array([1, 2, 3, 4]);
  const nativeApi = globalThis.native;
  const out = await nativeApi.chain(["invert", "invert"], input);

  return {
    ok: true,
    joined,
    out: Array.from(out),
  };
}

if (typeof process !== "undefined" && process.versions && process.versions.node) {
  main()
    .then((value) => {
      console.log(JSON.stringify(value));
    })
    .catch((err: unknown) => {
      const message = err instanceof Error && err.stack ? err.stack : String(err);
      console.error(message);
      process.exitCode = 1;
    });
}
