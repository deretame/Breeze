import { hostMd5Hex } from "./host-bridge";

export function nowTs(): string {
  return String(Date.now());
}

export function randomDeviceId(): string {
  const chars = "abcdefghijklmnopqrstuvwxyz0123456789";
  let out = "";
  for (let i = 0; i < 9; i += 1) {
    out += chars[Math.floor(Math.random() * chars.length)]!;
  }
  return out;
}

export async function md5Hex(text: string): Promise<string> {
  return hostMd5Hex(text);
}

export function getHost(url: string): string {
  try {
    return new URL(url).host;
  } catch {
    return "";
  }
}

export function toQueryString(
  input: Record<string, unknown> | undefined,
): string {
  if (!input) {
    return "";
  }

  const pairs: string[] = [];
  for (const [key, value] of Object.entries(input)) {
    if (value === undefined || value === null) {
      continue;
    }
    if (Array.isArray(value)) {
      for (const item of value) {
        pairs.push(
          `${encodeURIComponent(key)}=${encodeURIComponent(String(item))}`,
        );
      }
      continue;
    }
    pairs.push(
      `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`,
    );
  }
  return pairs.join("&");
}
