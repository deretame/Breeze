export default async function main(config: unknown = {}) {
  const cfg = (config || {}) as { baseUrl?: string };
  const baseUrl = String(cfg.baseUrl || "");
  if (!baseUrl || typeof fetch !== "function") {
    return { ok: false, reason: "fetch-or-base-url-missing" };
  }

    const getRes = await fetch(`${baseUrl}/fetch-case`);
    const getData = await getRes.json() as { path?: string; method?: string };

    const params = new URLSearchParams();
    params.append("name", "quickjs");
    params.append("lang", "rust");
    const urlRes = await fetch(`${baseUrl}/fetch-url`, {
      method: "POST",
      body: params,
    });
    const urlData = await urlRes.json() as {
      method?: string;
      body?: string;
      headers?: Record<string, string>;
    };

    const fd = new FormData();
    fd.append("name", "quickjs");
    fd.append("lang", "rust");
    fd.append("upload", new Blob(["hello"], { type: "text/plain" }), "a.txt");
    const formRes = await fetch(`${baseUrl}/fetch-form`, {
      method: "POST",
      body: fd,
    });
    const formData = await formRes.json() as {
      method?: string;
      body?: string;
      headers?: Record<string, string>;
    };

  return {
    ok:
      getRes.status === 200
      && getData.path === "/fetch-case"
      && getData.method === "GET"
      && urlRes.status === 200
      && urlData.method === "POST"
      && urlData.body === "name=quickjs&lang=rust"
      && String(urlData.headers?.["content-type"] || "")
        .includes("application/x-www-form-urlencoded;charset=UTF-8")
      && formRes.status === 200
      && formData.method === "POST"
      && String(formData.headers?.["content-type"] || "").includes("multipart/form-data;")
      && String(formData.body || "").includes("name=\"name\"")
      && String(formData.body || "").includes("quickjs")
      && String(formData.body || "").includes("name=\"upload\"; filename=\"a.txt\""),
  };
}
