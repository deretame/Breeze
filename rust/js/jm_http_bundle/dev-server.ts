import { createHash } from "node:crypto";
import { mkdir, readFile } from "node:fs/promises";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { context } from "esbuild";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const host = process.env.BUNDLE_HOST || "127.0.0.1";
const port = Number(process.env.BUNDLE_PORT || "7878");

const outDir = resolve(__dirname, "dist");
const outFile = resolve(outDir, "jm_http.bundle.cjs");

type BuildState = {
  ok: boolean;
  builtAt: string | null;
  version: string | null;
  sha256: string | null;
  size: number;
  error: string | null;
};

const state: BuildState = {
  ok: false,
  builtAt: null,
  version: null,
  sha256: null,
  size: 0,
  error: null,
};

let rebuildCount = 0;

function nowIso(): string {
  return new Date().toISOString();
}

function setCommonHeaders(res: ServerResponse, contentType?: string): void {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  if (contentType) {
    res.setHeader("Content-Type", contentType);
  }
}

async function refreshBuildState(): Promise<void> {
  const bytes = await readFile(outFile);
  const sha256 = createHash("sha256").update(bytes).digest("hex");
  const builtAt = new Date().toISOString();
  const version = sha256;

  state.ok = true;
  state.builtAt = builtAt;
  state.version = version;
  state.sha256 = sha256;
  state.size = bytes.byteLength;
  state.error = null;

  const bundleUrl = `http://${host}:${port}/jm_http.bundle.cjs`;
  const versionedBundleUrl = `${bundleUrl}?v=${version}`;
  console.error(
    `[bundle-dev] built version=${version} sha256=${sha256.slice(0, 12)} size=${bytes.byteLength}`,
  );
  console.error(`[bundle-dev] bundle url: ${bundleUrl}`);
  console.error(`[bundle-dev] bundle url (versioned): ${versionedBundleUrl}`);
}

async function handleBundle(res: ServerResponse): Promise<void> {
  try {
    const bytes = await readFile(outFile);
    setCommonHeaders(res, "application/javascript; charset=utf-8");
    if (state.sha256) {
      res.setHeader("ETag", `"${state.sha256}"`);
    }
    res.setHeader("Cache-Control", "no-cache");
    res.statusCode = 200;
    res.end(bytes);
  } catch (err) {
    setCommonHeaders(res, "text/plain; charset=utf-8");
    res.statusCode = 503;
    res.end(`bundle not ready: ${String(err)}`);
  }
}

function handleVersion(res: ServerResponse): void {
  setCommonHeaders(res, "application/json; charset=utf-8");
  res.statusCode = state.ok ? 200 : 503;
  res.end(
    JSON.stringify(
      {
        ok: state.ok,
        version: state.version,
        builtAt: state.builtAt,
        sha256: state.sha256,
        size: state.size,
        bundleUrl: `http://${host}:${port}/jm_http.bundle.cjs`,
        error: state.error,
      },
      null,
      2,
    ),
  );
}

function handleDefault(res: ServerResponse): void {
  setCommonHeaders(res, "text/plain; charset=utf-8");
  res.statusCode = 200;
  res.end(
    [
      "bundle dev server is running",
      `bundle: http://${host}:${port}/jm_http.bundle.cjs`,
      `meta:   http://${host}:${port}/version.json`,
    ].join("\n"),
  );
}

async function route(req: IncomingMessage, res: ServerResponse): Promise<void> {
  if (req.method === "OPTIONS") {
    setCommonHeaders(res);
    res.statusCode = 204;
    res.end();
    return;
  }

  const rawUrl = req.url || "/";
  let pathname = rawUrl;
  try {
    pathname = new URL(rawUrl, `http://${host}:${port}`).pathname;
  } catch {}

  if (pathname === "/version.json") {
    handleVersion(res);
    return;
  }

  if (pathname === "/jm_http.bundle.cjs") {
    await handleBundle(res);
    return;
  }

  handleDefault(res);
}

async function start(): Promise<void> {
  await mkdir(outDir, { recursive: true });

  const watchPlugin = {
    name: "watch-state-plugin",
    setup(build: import("esbuild").PluginBuild): void {
      build.onEnd(async (result) => {
        rebuildCount += 1;
        const ts = nowIso();
        if (result.errors.length > 0) {
          state.ok = false;
          state.error = result.errors[0]?.text || "build failed";
          console.error(`[bundle-dev] [${ts}] rebuild #${rebuildCount} failed: ${state.error}`);
          return;
        }

        try {
          await refreshBuildState();
          console.error(`[bundle-dev] [${ts}] rebuild #${rebuildCount} completed`);
        } catch (err) {
          state.ok = false;
          state.error = String(err);
          console.error(
            `[bundle-dev] [${ts}] rebuild #${rebuildCount} read output failed: ${state.error}`,
          );
        }
      });
    },
  };

  const ctx = await context({
    entryPoints: [resolve(__dirname, "src/index.ts")],
    bundle: true,
    platform: "browser",
    format: "cjs",
    target: ["es2019"],
    outfile: outFile,
    plugins: [watchPlugin],
  });

  await ctx.watch();

  const server = createServer((req, res) => {
    const startAt = Date.now();
    res.on("finish", () => {
      const method = req.method || "GET";
      const path = req.url || "/";
      const elapsedMs = Date.now() - startAt;
      console.error(`[bundle-dev] ${method} ${path} -> ${res.statusCode} (${elapsedMs}ms)`);
    });
    void route(req, res);
  });

  server.listen(port, host, () => {
    console.error(`[bundle-dev] listening at http://${host}:${port}`);
    console.error(`[bundle-dev] watching ${resolve(__dirname, "src")}`);
  });

  const shutdown = async (): Promise<void> => {
    console.error("[bundle-dev] shutting down...");
    server.close();
    await ctx.dispose();
    process.exit(0);
  };

  process.on("SIGINT", () => {
    void shutdown();
  });
  process.on("SIGTERM", () => {
    void shutdown();
  });
}

start().catch((err) => {
  console.error(`[bundle-dev] failed to start: ${String(err)}`);
  process.exit(1);
});
