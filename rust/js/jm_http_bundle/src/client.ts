import type { AxiosResponse } from "axios";
import axios from "axios";
import { decodeResponsePayload } from "./codec";
import { JM_VERSION } from "./constants";
import { resolveServerMessage, toFriendlyError } from "./errors";
import {
  cacheKeyFromConfig,
  getCachedResponse,
  getJwtToken,
  getUserAgent,
  setCachedResponse,
  setJwtToken,
} from "./state";
import type { JmMeta, JmRequestConfig } from "./types";
import { getHost, md5Hex, nowTs } from "./utils";

export function createJmClient() {
  const client = axios.create({
    // adapter: "fetch",
    timeout: 10000,
    validateStatus: () => true,
  });

  client.interceptors.request.use(async (config) => {
    const cfg = config as JmRequestConfig;
    const method = String(cfg.method || "GET").toUpperCase();
    const url = String(cfg.url || "");
    const meta: JmMeta = cfg.__jmMeta || {
      ts: nowTs(),
      cacheEnabled: false,
      useJwt: true,
    };

    const token = await md5Hex(`${meta.ts}${JM_VERSION}`);
    const authHeaders: Record<string, string> = {
      token,
      tokenparam: `${meta.ts},${JM_VERSION}`,
      "user-agent": getUserAgent(),
    };

    const host = getHost(url);
    if (host) {
      authHeaders.Host = host;
    }

    if (meta.useJwt) {
      const jwt = getJwtToken();
      if (jwt) {
        authHeaders.Authorization = `Bearer ${jwt}`;
      }
    }

    cfg.headers = {
      ...(cfg.headers as Record<string, unknown>),
      ...authHeaders,
    } as unknown as JmRequestConfig["headers"];

    if (meta.cacheEnabled && method === "GET") {
      const cacheConfig = {
        method,
        url,
        params: cfg.params as Record<string, unknown> | undefined,
        data: cfg.data,
      };
      meta.cacheKey = cacheKeyFromConfig(cacheConfig);
      const cached = getCachedResponse(cacheConfig);
      if (cached !== null && cached !== undefined) {
        meta.fromCache = true;
        cfg.adapter = async () => ({
          data: cached,
          status: 200,
          statusText: "OK",
          headers: {},
          config: cfg,
          request: undefined,
        });
      }
    }

    cfg.__jmMeta = meta;
    return cfg;
  });

  client.interceptors.response.use(
    async (response: AxiosResponse) => {
      const cfg = response.config as JmRequestConfig;
      const meta = cfg.__jmMeta;

      if (meta?.fromCache) {
        return response;
      }

      const decoded = await decodeResponsePayload(
        response.data,
        meta?.ts || nowTs(),
      );
      const status = Number(response.status || 0);

      if (status < 200 || status >= 300) {
        const serverMsg = resolveServerMessage(
          decoded,
          `服务器响应异常 (${status || "unknown"})`,
        );
        if (status === 401 || serverMsg === "請先登入會員") {
          throw new Error("登录过期，请重新登录");
        }
        throw new Error(serverMsg);
      }

      if (decoded && typeof decoded === "object" && !Array.isArray(decoded)) {
        const nextJwt = String(
          (decoded as Record<string, unknown>).jwttoken || "",
        ).trim();
        if (nextJwt) {
          setJwtToken(nextJwt);
        }
      }

      if (
        meta?.cacheEnabled &&
        String(cfg.method || "GET").toUpperCase() === "GET"
      ) {
        setCachedResponse(
          {
            method: String(cfg.method || "GET").toUpperCase(),
            url: String(cfg.url || ""),
            params: cfg.params as Record<string, unknown> | undefined,
            data: cfg.data,
          },
          decoded,
        );
      }

      response.data = decoded;
      return response;
    },
    (err: unknown) => Promise.reject(toFriendlyError(err)),
  );

  return client;
}
