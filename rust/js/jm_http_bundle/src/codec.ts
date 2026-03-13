import pako from "pako";
import { JM_SECRET } from "./constants";
import { hostAesEcbPkcs7DecryptB64 } from "./host-bridge";
import { md5Hex } from "./utils";

function tryParseJson(raw: string): unknown | null {
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function maybeGunzipBytes(bytes: Uint8Array): Uint8Array {
  if (bytes.length >= 2 && bytes[0] === 0x1f && bytes[1] === 0x8b) {
    try {
      return pako.ungzip(bytes);
    } catch {
      return bytes;
    }
  }
  return bytes;
}

function bytesToUtf8(bytes: Uint8Array): string {
  try {
    return new TextDecoder("utf-8").decode(bytes);
  } catch {
    return "";
  }
}

async function decryptDataField(
  payload: string,
  ts: string,
): Promise<unknown | null> {
  const tsRaw = String(ts || "").trim();
  if (!tsRaw) {
    return null;
  }

  try {
    const key = await md5Hex(`${tsRaw}${JM_SECRET}`);
    const text = await hostAesEcbPkcs7DecryptB64(payload, key);
    if (!text.trim()) {
      return null;
    }
    return tryParseJson(text.trim()) ?? text;
  } catch {
    return null;
  }
}

function normalizeRawResponse(raw: unknown): unknown {
  if (raw === null || raw === undefined || typeof raw === "string") {
    return raw;
  }

  if (raw instanceof ArrayBuffer) {
    return bytesToUtf8(maybeGunzipBytes(new Uint8Array(raw)));
  }

  if (ArrayBuffer.isView(raw)) {
    return bytesToUtf8(
      maybeGunzipBytes(
        new Uint8Array(raw.buffer, raw.byteOffset, raw.byteLength),
      ),
    );
  }

  return raw;
}

async function decodeValue(value: unknown, ts: string): Promise<unknown> {
  console.debug(`decodeValue value type: ${typeof value}`);

  if (typeof value === "string") {
    const raw = value.trim();
    if (!raw) {
      return "";
    }
    const parsed = tryParseJson(raw);
    if (parsed !== null) {
      return decodeValue(parsed, ts);
    }
    return value;
  }

  if (Array.isArray(value)) {
    return value;
  }

  if (value && typeof value === "object") {
    const obj = Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([k, v]) => [
        String(k),
        v,
      ]),
    );
    const dataField = obj.data;
    if (typeof dataField === "string" && dataField.trim()) {
      const decrypted = await decryptDataField(dataField.trim(), ts);
      if (decrypted !== null) {
        return decrypted;
      }

      const parsed = tryParseJson(dataField.trim());
      if (parsed !== null) {
        return parsed;
      }
    }
    return obj;
  }

  return value;
}

export async function decodeResponsePayload(
  raw: unknown,
  ts: string,
): Promise<unknown> {
  return decodeValue(normalizeRawResponse(raw), ts);
}
