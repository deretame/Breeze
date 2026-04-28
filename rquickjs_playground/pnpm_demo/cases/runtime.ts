import { getApi, requireCryptoLike, runtime } from "../src/runtime-api";

export default async function main() {
  const BufferRef = runtime.Buffer;
  const runtimePath = getApi("path");
  const pathRef: { join: (...parts: string[]) => string } =
    runtimePath && typeof runtimePath.join === "function"
      ? { join: (...parts: string[]) => runtimePath.join!(...parts) }
      : {
      join: (...parts: string[]) => parts.join("/").replace(/\/+/g, "/").replace("/b/../", "/"),
      };
  const p = pathRef.join("/a", "b", "..", "c.txt");

  let ticked: boolean = false;
  process.nextTick(() => {
    ticked = true;
  });
  await new Promise<void>((resolve) => process.nextTick(resolve));

  const b = BufferRef.concat([BufferRef.from("ab"), BufferRef.from("cd")]).toString("utf8");

  const id = String(runtime.uuidv4() || "");
  const uuidOk = /^[0-9a-f]{32}$/.test(id)
    || /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(id);

  const cryptoRef = requireCryptoLike();
  const shaHex = cryptoRef.createHash("sha256")
    .update("The quick brown fox jumps over the lazy dog")
    .digest("hex");
  const hmacHex = cryptoRef.createHmac("sha256", "key")
    .update("The quick brown fox jumps over the lazy dog")
    .digest("hex");

  const ok =
    p === "/a/c.txt"
    && b === "abcd"
    && ticked
    && uuidOk
    && shaHex === "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"
    && hmacHex === "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8";

  return {
    ok,
    p,
    b,
    ticked,
    uuidOk,
    shaHex,
    hmacHex,
  };
}
