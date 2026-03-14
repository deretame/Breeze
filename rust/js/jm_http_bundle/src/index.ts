import axios from "axios";
import { createJmClient } from "./client";
import { toFriendlyError } from "./errors";
import { buildRequestConfig } from "./request-config";
import { getCachedResponse } from "./state";
import type { RequestPayload } from "./types";

const jmClient = createJmClient();

async function fetchImageBytes(args: { url: string; timeoutMs: number }) {
  console.debug("fetchImageBytes", args);
  const targetUrl = String(args.url || "").trim();
  if (!targetUrl) throw new Error("url 不能为空");

  const timeout =
    Number.isFinite(args.timeoutMs) && args.timeoutMs > 0
      ? Math.floor(args.timeoutMs)
      : 30_000;

  const headers: Record<string, string> = {};

  try {
    headers.Host = new URL(targetUrl).host;
  } catch {}

  try {
    const response = await axios.get<ArrayBuffer>(targetUrl, {
      headers,
      timeout,
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
    console.error(err);
    throw err;
  }
}

async function request(input: RequestPayload) {
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

function helloWorld() {
  console.debug("Hello World!");
}

export default {
  request,
  fetchImageBytes,
  helloWorld,
};
