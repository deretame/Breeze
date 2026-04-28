import { getApi, requireApi, requireCryptoLike, runtime } from "../src/runtime-api";

export default async function main(config: unknown = {}) {
  const cfg = (config || {}) as { baseDir?: string; baseUrl?: string };
  const baseDir = String(cfg.baseDir || "");
  const baseUrl = String(cfg.baseUrl || "");

  const crypto = requireCryptoLike();
  const shaHex = crypto.createHash("sha256").update("The quick brown fox jumps over the lazy dog").digest("hex");
  const hmacHex = crypto.createHmac("sha256", "key").update("The quick brown fox jumps over the lazy dog").digest("hex");

  const id = runtime.uuidv4();
  const uuidOk = /^[0-9a-f]{32}$/i.test(id)
    || /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(id);

  const pathApi = getApi("path");
  const joined = pathApi
    ? pathApi.join("/a", "b", "..", "c.txt")
    : ["/a", "b", "..", "c.txt"].join("/").replace(/\/+/g, "/").replace("/b/../", "/");

  const bridge = requireApi("bridge");
  const bridgeSum = await bridge.call("math.add", 1.5, 2) as number;

  const native = requireApi("native");
  const nativeOut = await native.chain(["invert", "invert"], new Uint8Array([1, 2, 3]));

  const wasi = requireApi("wasi");
  const moduleBytes = new Uint8Array([
      0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
      0x01, 0x04, 0x01, 0x60, 0x00, 0x00,
      0x03, 0x02, 0x01, 0x00,
      0x07, 0x0a, 0x01, 0x06, 0x5f, 0x73, 0x74, 0x61, 0x72, 0x74, 0x00, 0x00,
      0x0a, 0x04, 0x01, 0x02, 0x00, 0x0b,
    ]);
  const wasiRun = await wasi.run(moduleBytes);
  const wasiStdout = await wasi.takeStdout(wasiRun);
  const wasiStderr = await wasi.takeStderr(wasiRun);

  const fsApi = requireApi("fs");
  const filePath = `${baseDir}/runtime-api.txt`;
  await fsApi.promises.writeFile(filePath, "hello-runtime-api");
  const fileRaw = await fsApi.promises.readFile(filePath);
  const fileText = typeof fileRaw === "string"
    ? fileRaw
    : new runtime.TextDecoder().decode(fileRaw);
  await fsApi.promises.rm(filePath, { force: true });

  const fetchFn = requireApi("fetch");

  const formData = new runtime.FormData();
  formData.append("name", "runtime-api");

  const ok =
    shaHex === "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"
    && hmacHex === "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8"
    && uuidOk
    && joined === "/a/c.txt"
    && bridgeSum === 3.5
    && nativeOut[0] === 1
    && nativeOut[1] === 2
    && nativeOut[2] === 3
    && wasiRun.exitCode === 0
    && wasiStdout.length === 0
    && wasiStderr.length === 0
    && fileText === "hello-runtime-api"
    && typeof fetchFn === "function"
    && formData.get("name") === "runtime-api";

  return {
    ok,
    joined,
    uuidOk,
    bridgeSum,
    fileText,
    hasFetch: typeof fetchFn === "function",
  };
}
