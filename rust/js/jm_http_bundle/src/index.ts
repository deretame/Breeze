import { createJmClient } from "./client";
import { toFriendlyError } from "./errors";
import { buildRequestConfig } from "./request-config";
import { getCachedResponse } from "./state";
import type { RequestPayload } from "./types";
import axios from "axios";

const jmClient = createJmClient();
const FETCH_TIMEOUT_SENTINEL = "__QJS_FETCH_IMAGE_TIMEOUT__";

async function fetchImageBytes(
  url: string,
  timeoutMs: number = 30_000,
): Promise<{ nativeBufferId: number }> {
  const targetUrl = String(url || "").trim();
  if (!targetUrl) {
    throw new Error("url 不能为空");
  }

  if (!native || typeof native.put !== "function") {
    throw new Error("运行时缺少 native.put 能力");
  }

  const timeout = Number.isFinite(timeoutMs) && timeoutMs > 0
    ? Math.floor(timeoutMs)
    : 30_000;

  const headers: Record<string, string> = {
    "User-Agent": "#",
    Connection: "Keep-Alive",
    "Accept-Encoding": "gzip",
  };

  try {
    headers.Host = new URL(targetUrl).host;
  } catch (_err) {
  }

  const controller = typeof AbortController === "function"
    ? new AbortController()
    : null;
  let timeoutId: ReturnType<typeof setTimeout> | null = null;
  let timeoutFired = false;
  if (controller) {
    timeoutId = setTimeout(() => {
      timeoutFired = true;
      controller.abort();
    }, timeout);
  }

  try {
    const response = await axios.get<ArrayBuffer>(targetUrl, {
      headers,
      timeout,
      signal: controller?.signal,
      responseType: "arraybuffer",
      validateStatus: () => true,
    });

    if (response.status < 200 || response.status >= 300) {
      throw new Error(`下载图片失败: HTTP ${response.status}`);
    }

    const bytes = new Uint8Array(response.data);
    const nativeBufferId = await native.put(bytes);
    return { nativeBufferId: Number(nativeBufferId) };
  } catch (err) {
    if (timeoutFired) {
      throw FETCH_TIMEOUT_SENTINEL;
    }
    let code = "";
    let message = "";
    try {
      code = String((err as { code?: string } | null)?.code || "");
    } catch (_e) {
    }
    try {
      message = String((err as { message?: string } | null)?.message || "").toLowerCase();
    } catch (_e) {
    }
    if (code === "ECONNABORTED" || message.includes("timeout")) {
      throw FETCH_TIMEOUT_SENTINEL;
    }
    const friendly = toFriendlyError(err);
    if (friendly instanceof Error) {
      throw friendly.message || "下载图片失败";
    }
    throw String(friendly || "下载图片失败");
  } finally {
    if (timeoutId !== null) {
      clearTimeout(timeoutId);
    }
  }
}

async function request(input: RequestPayload): Promise<unknown> {
  const { config, cacheEnabled } = buildRequestConfig(input);

  try {
    const response = await jmClient.request(config);
    return response.data;
  } catch (err) {
    if (
      cacheEnabled &&
      String(config.method || "GET").toUpperCase() === "GET"
    ) {
      const cached = getCachedResponse({
        method: String(config.method || "GET").toUpperCase(),
        url: String(config.url || ""),
        params: config.params as Record<string, unknown> | undefined,
        data: config.data,
      });
      if (cached !== null && cached !== undefined) {
        return cached;
      }
    }
    throw toFriendlyError(err);
  }
}

export default {
  request,
  fetchImageBytes,
};
