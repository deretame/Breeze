export default async function main() {
  const wasiApi = globalThis.wasi;
  const nativeApi = globalThis.native;
  if (!wasiApi || !nativeApi) {
    return { ok: false, reason: "runtime-wasi-or-native-missing" };
  }

    const wasm = new Uint8Array([
      0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00,
      0x01, 0x04, 0x01, 0x60, 0x00, 0x00,
      0x03, 0x02, 0x01, 0x00,
      0x07, 0x0a, 0x01, 0x06, 0x5f, 0x73, 0x74, 0x61, 0x72, 0x74, 0x00, 0x00,
      0x0a, 0x04, 0x01, 0x02, 0x00, 0x0b,
    ]);

    const once = await wasiApi.run(wasm);
    const stdout = await wasiApi.takeStdout(once);
    const stderr = await wasiApi.takeStderr(once);

    const moduleId = await nativeApi.put(wasm);
    const r1 = await wasiApi.runById(moduleId, { reuseModule: true });
    const r2 = await wasiApi.runById(moduleId, { reuseModule: true });
    await wasiApi.takeStdout(r1);
    await wasiApi.takeStderr(r1);
    await wasiApi.takeStdout(r2);
    await wasiApi.takeStderr(r2);
    await nativeApi.free(moduleId);

  return {
    ok:
      once.exitCode === 0 &&
      stdout.length === 0 &&
      stderr.length === 0 &&
      r1.exitCode === 0 &&
      r2.exitCode === 0,
  };
}
