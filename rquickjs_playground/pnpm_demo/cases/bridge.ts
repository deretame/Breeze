import { getApi, requireApi } from "../src/runtime-api";

export default async function main() {
  const maybeBridge = getApi("bridge");
  if (!maybeBridge || typeof maybeBridge.call !== "function") {
    return { ok: false, reason: "bridge-missing" };
  }

  const bridge = requireApi("bridge");
  const inputId = await bridge.call("native.put", [1, 2, 3]);
  const outId = await bridge.call("native.exec", "invert", inputId, null, null);
  const out = await bridge.call("native.take", outId) as number[] | Uint8Array;
  const sum = await bridge.call("math.add", 1.5, 2);
  const bytes = out instanceof Uint8Array ? Array.from(out) : out;

  return {
    ok: Array.isArray(bytes) && bytes[0] === 254 && bytes[1] === 253 && bytes[2] === 252 && sum === 3.5,
  };
}
