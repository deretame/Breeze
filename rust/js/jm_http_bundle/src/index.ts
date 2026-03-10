import { createJmClient } from "./client";
import { toFriendlyError } from "./errors";
import { buildRequestConfig } from "./request-config";
import { getCachedResponse } from "./state";
import type { RequestPayload } from "./types";

const jmClient = createJmClient();

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
};
