export function resolveServerMessage(data: unknown, fallback: string): string {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return fallback;
  }

  const map = data as Record<string, unknown>;
  const raw = map.errorMsg ?? map.msg ?? map.message;
  const text = String(raw || "").trim();
  return text || fallback;
}

export function toFriendlyNetworkError(err: unknown): string {
  const code = String((err as { code?: string } | null)?.code || "");
  const message = String(
    (err as { message?: string } | null)?.message || "",
  ).toLowerCase();

  if (code === "ECONNABORTED" || message.includes("timeout")) {
    return "连接服务器超时";
  }
  if (code === "ERR_NETWORK") {
    return "网络连接失败";
  }
  if (code === "ERR_CANCELED") {
    return "请求被取消";
  }
  return "未知网络错误";
}

export function toFriendlyError(err: unknown): Error {
  console.error(`禁漫请求失败: ${err}`);
  if (err instanceof Error && err.message.trim()) {
    return err;
  }
  return new Error(toFriendlyNetworkError(err));
}
