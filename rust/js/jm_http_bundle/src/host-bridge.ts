function requireBridge(): NonNullable<typeof bridge> {
  if (!bridge || typeof bridge.call !== "function") {
    throw new Error("bridge.call 不可用");
  }
  return bridge;
}

export async function hostMd5Hex(input: string): Promise<string> {
  const out = await requireBridge().call("crypto.md5_hex", String(input || ""));
  return String(out || "");
}

export async function hostAesEcbPkcs7DecryptB64(
  payloadB64: string,
  keyRaw: string,
): Promise<string> {
  const out = await requireBridge().call(
    "crypto.aes_ecb_pkcs7_decrypt_b64",
    String(payloadB64 || ""),
    String(keyRaw || ""),
  );
  return String(out || "");
}
