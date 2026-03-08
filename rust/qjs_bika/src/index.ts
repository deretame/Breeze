(() => {
  const API_KEY = "C69BAF41DA5ABD1FFEDC6D2FEA56B";
  const SECRET_KEY = "~d}$Q7$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn";
  const BASE_URL = "https://picaapi.picacomic.com/";

  type RequestPayload = {
    method: string;
    url: string;
    body?: unknown;
    authorization?: string | null;
    imageQuality?: string;
    appChannel?: string;
  };

  function cleanPath(url: string): string {
    return url.replace(BASE_URL, "");
  }

  function nonce(): string {
    const fn = (globalThis as { uuidv4?: () => string }).uuidv4;
    if (typeof fn === "function") {
      return fn().replace(/-/g, "");
    }
    return `${Date.now()}${Math.random()}`.replace(/[^0-9a-z]/gi, "");
  }

  function sign(path: string, ts: number, currentNonce: string, method: string): string {
    const cryptoRef = (globalThis as { crypto?: { createHmac?: (alg: string, key: string) => { update: (s: string, enc?: string) => { digest: (enc: string) => string } } } }).crypto;
    if (!cryptoRef || typeof cryptoRef.createHmac !== "function") {
      throw new TypeError("crypto.createHmac 不可用");
    }
    const raw = `${path}${ts}${currentNonce}${method}${API_KEY}`.toLowerCase();
    return cryptoRef.createHmac("sha256", SECRET_KEY).update(raw, "utf8").digest("hex");
  }

  function toResponseObject(status: number, text: string): Record<string, unknown> {
    if (!text) {
      return { code: status, message: "empty response", data: null };
    }
    try {
      const parsed = JSON.parse(text);
      if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
        return parsed as Record<string, unknown>;
      }
      return { code: status, data: parsed };
    } catch (_err) {
      return { code: status, message: text, data: null };
    }
  }

  async function request(payload: RequestPayload): Promise<Record<string, unknown>> {
    const method = String(payload.method || "GET").toUpperCase();
    const url = String(payload.url || "").trim();
    if (!url) {
      throw new TypeError("url 不能为空");
    }

    const ts = Math.floor(Date.now() / 1000);
    const currentNonce = nonce();
    const signature = sign(cleanPath(url), ts, currentNonce, method);

    const headers: Record<string, string> = {
      "api-key": API_KEY,
      accept: "application/vnd.picacomic.com.v1+json",
      "app-channel": String(payload.appChannel ?? "3"),
      time: String(ts),
      nonce: currentNonce,
      signature,
      "app-version": "2.2.1.3.3.4",
      "app-uuid": "defaultUuid",
      "app-platform": "android",
      "app-build-version": "45",
      "accept-encoding": "gzip",
      "user-agent": "okhttp/3.8.1",
      "content-type": "application/json; charset=UTF-8",
      "image-quality": String(payload.imageQuality || "original"),
    };

    const auth = typeof payload.authorization === "string" ? payload.authorization.trim() : "";
    if (auth) {
      headers.authorization = auth;
    }

    const init: RequestInit = { method, headers };
    if (method !== "GET" && method !== "HEAD" && payload.body !== undefined && payload.body !== null) {
      init.body = typeof payload.body === "string" ? payload.body : JSON.stringify(payload.body);
    }

    try {
      const res = await fetch(url, init);
      const text = await res.text();
      return toResponseObject(res.status, text);
    } catch (err) {
      return {
        code: -1,
        message: err instanceof Error ? err.message : String(err),
        data: null,
      };
    }
  }

  async function dispatch(payload: unknown): Promise<Record<string, unknown>> {
    if (!payload || typeof payload !== "object") {
      throw new TypeError("payload 必须是对象");
    }
    const action = String((payload as { action?: string }).action || "");
    if (action !== "request") {
      throw new TypeError(`不支持的 action: ${action}`);
    }
    const req = (payload as { request?: RequestPayload }).request;
    if (!req) {
      throw new TypeError("缺少 request");
    }
    return request(req);
  }

  (globalThis as { __bika_dispatch?: (payload: unknown) => Promise<Record<string, unknown>> }).__bika_dispatch = dispatch;
})();
