import { nowTs, toQueryString } from "./utils";
import { setJwtToken } from "./state";
import type { JmRequestConfig, RequestPayload } from "./types";

export function buildRequestConfig(input: RequestPayload): {
  config: JmRequestConfig;
  cacheEnabled: boolean;
} {
  const method = String(input.method || "GET").toUpperCase();
  const url = String(input.path || input.url || "").trim();
  if (!url) {
    throw new Error("请求地址不能为空");
  }

  const headers: Record<string, string> = {};
  const inputJwt = String(input.jwtToken || "").trim();
  if (inputJwt) {
    setJwtToken(inputJwt);
  }

  let body = input.data;
  if (method === "POST" && input.formData) {
    body = toQueryString(input.formData);
    headers["content-type"] = "application/x-www-form-urlencoded";
  } else if (method === "POST" && typeof body === "string") {
    headers["content-type"] = headers["content-type"] || "application/x-www-form-urlencoded";
  }

  const cacheEnabled = input.cache === true;
  const config: JmRequestConfig = {
    method,
    url,
    params: input.params,
    data: body,
    headers: headers as unknown as JmRequestConfig["headers"],
    timeout: 10000,
    responseType: "arraybuffer",
    validateStatus: () => true,
    __jmMeta: {
      ts: nowTs(),
      cacheEnabled,
      useJwt: input.useJwt !== false,
    },
  };

  return { config, cacheEnabled };
}
