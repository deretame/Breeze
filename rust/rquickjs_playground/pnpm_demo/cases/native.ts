export default async function main() {
  const nativeApi = globalThis.native;
  if (!nativeApi) {
    return { ok: false, reason: "runtime-native-missing" };
  }
  const out = await nativeApi.chain(["invert", "invert"], new Uint8Array([7, 8, 9]));
  return { ok: out[0] === 7 && out[1] === 8 && out[2] === 9 };
}
