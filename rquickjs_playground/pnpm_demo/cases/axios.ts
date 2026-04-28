import axios from "axios";

type AxiosCaseConfig = { baseUrl?: string };

function hasQuery(path: string, key: string, value: string): boolean {
  return path.includes(`${key}=${encodeURIComponent(value)}`) || path.includes(`${key}=${value}`);
}

function parseJsonBody(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

async function runGet(client: ReturnType<typeof axios.create>) {
  const res = await client.get("/axios-get?x=1");
  return {
    ok: res.status === 200 && res.data?.method === "GET" && res.data?.path === "/axios-get?x=1",
    path: String(res.data?.path || ""),
  };
}

async function runPost(client: ReturnType<typeof axios.create>) {
  const payload = { lib: "axios", case: "bundle" };
  const res = await client.post("/axios-post", payload);
  const parsed = parseJsonBody(String(res.data?.body || "")) as { lib?: string; case?: string } | null;
  return {
    ok:
      res.status === 200
      && res.data?.method === "POST"
      && res.data?.path === "/axios-post"
      && parsed?.lib === "axios"
      && parsed?.case === "bundle",
    body: String(res.data?.body || ""),
  };
}

async function runParams(client: ReturnType<typeof axios.create>) {
  const res = await client.get("/axios-params", { params: { a: 1, b: "ok" } });
  const path = String(res.data?.path || "");
  return {
    ok: res.status === 200 && path.startsWith("/axios-params?") && hasQuery(path, "a", "1") && hasQuery(path, "b", "ok"),
    path,
  };
}

async function runInterceptor(client: ReturnType<typeof axios.create>) {
  const interceptorId = client.interceptors.request.use((config) => {
    const headers = config.headers || {};
    headers["x-axios-interceptor"] = "yes";
    config.headers = headers;
    return config;
  });

  try {
    const res = await client.get("/axios-interceptor");
    const got = String(res.data?.headers?.["x-axios-interceptor"] || "");
    return {
      ok: res.status === 200 && res.data?.path === "/axios-interceptor" && got === "yes",
      header: got,
    };
  } finally {
    client.interceptors.request.eject(interceptorId);
  }
}

async function runResponseInterceptor(client: ReturnType<typeof axios.create>) {
  const interceptorId = client.interceptors.response.use((response) => {
    const cloned = response;
    cloned.data = {
      ...(response.data || {}),
      interceptedByResponse: true,
    };
    return cloned;
  });

  try {
    const res = await client.get("/axios-response-interceptor");
    return {
      ok:
        res.status === 200
        && res.data?.path === "/axios-response-interceptor"
        && res.data?.interceptedByResponse === true,
      intercepted: Boolean(res.data?.interceptedByResponse),
    };
  } finally {
    client.interceptors.response.eject(interceptorId);
  }
}

async function runFormData(client: ReturnType<typeof axios.create>) {
  const fd = new FormData();
  fd.append("name", "axios");
  fd.append("mode", "fetch-adapter");
  fd.append("upload", new Blob(["hello-axios"], { type: "text/plain" }), "a.txt");

  const res = await client.post("/axios-form", fd, {
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
  const body = String(res.data?.body || "");
  const contentType = String(res.data?.headers?.["content-type"] || "");

  return {
    ok:
      res.status === 200
      && res.data?.method === "POST"
      && res.data?.path === "/axios-form"
      && contentType.includes("multipart/form-data")
      && body.length > 0,
    contentType,
    bodyLen: body.length,
  };
}

async function runConcurrent(client: ReturnType<typeof axios.create>) {
  const [a, b] = await Promise.all([
    client.get("/axios-c1"),
    client.get("/axios-c2"),
  ]);

  return {
    ok:
      a.status === 200
      && b.status === 200
      && a.data?.path === "/axios-c1"
      && b.data?.path === "/axios-c2",
    p1: String(a.data?.path || ""),
    p2: String(b.data?.path || ""),
  };
}

async function runUrlEncoded(client: ReturnType<typeof axios.create>) {
  const params = new URLSearchParams();
  params.append("name", "axios");
  params.append("kind", "urlencoded");
  const res = await client.post("/axios-urlencoded", params);
  const body = String(res.data?.body || "");
  const contentType = String(res.data?.headers?.["content-type"] || "");
  return {
    ok:
      res.status === 200
      && res.data?.method === "POST"
      && res.data?.path === "/axios-urlencoded"
      && body.length > 0
      && (body.includes("name=axios") || body.includes("\"name\",\"axios\""))
      && (body.includes("kind=urlencoded") || body.includes("\"kind\",\"urlencoded\"")),
    body,
  };
}

async function runInstanceAndRequest(baseUrl: string) {
  const api = axios.create({
    baseURL: baseUrl,
    adapter: "fetch",
    headers: {
      "x-instance-default": "yes",
    },
  });

  const putRes = await api.request({
    url: "/axios-request",
    method: "PUT",
    data: { from: "request" },
    headers: {
      "x-request-level": "true",
    },
  });

  const body = parseJsonBody(String(putRes.data?.body || "")) as { from?: string } | null;
  const headers = (putRes.data?.headers || {}) as Record<string, string>;

  return {
    ok:
      putRes.status === 200
      && putRes.data?.method === "PUT"
      && putRes.data?.path === "/axios-request"
      && body?.from === "request"
      && String(headers["x-instance-default"] || "") === "yes"
      && String(headers["x-request-level"] || "") === "true",
    method: String(putRes.data?.method || ""),
  };
}

async function runAxiosHelpers(client: ReturnType<typeof axios.create>) {
  const [a, b] = await axios.all([
    client.get("/axios-all-1"),
    client.get("/axios-all-2"),
  ]);

  const spreadOut = axios.spread((r1: { data?: { path?: string } }, r2: { data?: { path?: string } }) => {
    return `${String(r1.data?.path || "")}|${String(r2.data?.path || "")}`;
  })([a, b]);

  return {
    ok: spreadOut === "/axios-all-1|/axios-all-2",
    spreadOut,
  };
}

async function runErrorShape() {
  try {
    await axios.get("http://127.0.0.1:1/axios-error-shape", {
      adapter: "fetch",
      timeout: 200,
    });
    return { ok: false, isAxiosError: false };
  } catch (err) {
    return {
      ok: axios.isAxiosError(err),
      isAxiosError: axios.isAxiosError(err),
    };
  }
}

async function runArrayBuffer(client: ReturnType<typeof axios.create>) {
  try {
    const res = await client.get("/axios-binary", {
      responseType: "arraybuffer",
    });

    let bytes: Uint8Array;
    const data = res.data as unknown;
    if (data instanceof ArrayBuffer) {
      bytes = new Uint8Array(data);
    } else if (ArrayBuffer.isView(data)) {
      bytes = new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
    } else if (typeof data === "string") {
      bytes = new TextEncoder().encode(data);
    } else {
      return {
        ok: false,
        len: 0,
        first: -1,
        last: -1,
        kind: typeof data,
      };
    }

    const expected = [0, 1, 2, 3, 250, 251, 252, 253, 254, 255];
    const same = bytes.length === expected.length && expected.every((v, i) => bytes[i] === v);

    return {
      ok: res.status === 200 && same,
      len: bytes.length,
      first: bytes[0],
      last: bytes[bytes.length - 1],
      kind: Object.prototype.toString.call(data),
    };
  } catch (err: unknown) {
    return {
      ok: false,
      len: 0,
      first: -1,
      last: -1,
      kind: err instanceof Error ? err.message : String(err),
    };
  }
}

export default async function main(config: unknown = {}) {
  const cfg = (config || {}) as AxiosCaseConfig;
  const baseUrl = String(cfg.baseUrl || "");
  if (!baseUrl) {
    return { ok: false, reason: "base-url-missing" };
  }

  axios.defaults.adapter = "fetch";

  const client = axios.create({
    baseURL: baseUrl,
    adapter: "fetch",
    timeout: 10_000,
    headers: { "x-axios-case": "bundle" },
  });

  const get = await runGet(client);
  const post = await runPost(client);
  const params = await runParams(client);
  const interceptor = await runInterceptor(client);
  const responseInterceptor = await runResponseInterceptor(client);
  const formData = await runFormData(client);
  const concurrent = await runConcurrent(client);
  const urlEncoded = await runUrlEncoded(client);
  const instanceRequest = await runInstanceAndRequest(baseUrl);
  const helpers = await runAxiosHelpers(client);
  const errorShape = await runErrorShape();
  const arrayBuffer = await runArrayBuffer(client);

  const ok = get.ok
    && post.ok
    && params.ok
    && interceptor.ok
    && responseInterceptor.ok
    && formData.ok
    && concurrent.ok
    && urlEncoded.ok
    && instanceRequest.ok
    && helpers.ok
    && errorShape.ok
    && arrayBuffer.ok;

  return {
    ok,
    adapter: String(axios.defaults.adapter || ""),
    checks: {
      get: get.ok,
      post: post.ok,
      params: params.ok,
      interceptor: interceptor.ok,
      responseInterceptor: responseInterceptor.ok,
      formData: formData.ok,
      concurrent: concurrent.ok,
      urlEncoded: urlEncoded.ok,
      instanceRequest: instanceRequest.ok,
      helpers: helpers.ok,
      errorShape: errorShape.ok,
      arrayBuffer: arrayBuffer.ok,
    },
    details: {
      getPath: get.path,
      postBody: post.body,
      paramsPath: params.path,
      interceptorHeader: interceptor.header,
      responseIntercepted: responseInterceptor.intercepted,
      formDataContentType: formData.contentType,
      formDataBodyLen: formData.bodyLen,
      concurrentP1: concurrent.p1,
      concurrentP2: concurrent.p2,
      urlEncodedBody: urlEncoded.body,
      instanceRequestMethod: instanceRequest.method,
      helperSpreadOut: helpers.spreadOut,
      errorIsAxiosError: errorShape.isAxiosError,
      arrayBufferLen: arrayBuffer.len,
      arrayBufferFirst: arrayBuffer.first,
      arrayBufferLast: arrayBuffer.last,
      arrayBufferKind: arrayBuffer.kind,
    },
  };
}
