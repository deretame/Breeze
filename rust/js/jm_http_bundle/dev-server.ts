import { createHash } from "node:crypto";
import { mkdir, readFile } from "node:fs/promises";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { basename, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { rspack, type MultiStats, type Stats } from "@rspack/core";
import { createRspackConfig } from "./rspack.shared";

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

function formatRspackError(err: unknown): string {
  if (typeof err === "string") {
    return err;
  }

  if (err && typeof err === "object") {
    const message = Reflect.get(err, "message");
    if (typeof message === "string" && message.length > 0) {
      return message;
    }

    const details = Reflect.get(err, "details");
    if (typeof details === "string" && details.length > 0) {
      return details;
    }
  }

  return String(err);
}

function getErrorFromStats(stats: Stats | MultiStats | undefined): string {
  if (!stats) {
    return "build failed";
  }

  const info = stats.toJson({ all: false, errors: true });
  const firstError = info.errors?.[0];
  if (!firstError) {
    return "build failed";
  }

  return formatRspackError(firstError);
}

function createCompiler() {
  return rspack(
    createRspackConfig({
      rootDir: __dirname,
      outPath: outDir,
      outFileName: basename(outFile),
    }),
  );
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
  const compiler = createCompiler();

  const watcher = compiler.watch({}, async (err, stats) => {
    rebuildCount += 1;
    const ts = nowIso();

    if (err) {
      state.ok = false;
      state.error = formatRspackError(err);
      console.error(`[bundle-dev] [${ts}] rebuild #${rebuildCount} failed: ${state.error}`);
      return;
    }

    if (!stats || stats.hasErrors()) {
      state.ok = false;
      state.error = getErrorFromStats(stats);
      console.error(`[bundle-dev] [${ts}] rebuild #${rebuildCount} failed: ${state.error}`);
      return;
    }

    try {
      await refreshBuildState();
      console.error(`[bundle-dev] [${ts}] rebuild #${rebuildCount} completed`);
    } catch (refreshErr) {
      state.ok = false;
      state.error = String(refreshErr);
      console.error(
        `[bundle-dev] [${ts}] rebuild #${rebuildCount} read output failed: ${state.error}`,
      );
    }
  });

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

    await new Promise<void>((resolveClose, rejectClose) => {
      try {
        watcher.close(() => {
          resolveClose();
        });
      } catch (closeErr) {
        rejectClose(closeErr);
      }
    });

    await new Promise<void>((resolveClose, rejectClose) => {
      try {
        compiler.close(() => {
          resolveClose();
        });
      } catch (closeErr) {
        rejectClose(closeErr);
      }
    });

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
