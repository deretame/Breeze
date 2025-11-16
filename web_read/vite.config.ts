import { defineConfig, type Plugin, type ViteDevServer } from "vite";
import vue from "@vitejs/plugin-vue";
import fs from "node:fs";
import path from "node:path";
import type { IncomingMessage, ServerResponse } from "node:http";
import type { NextFunction } from "connect";

export default defineConfig({
  plugins: [vue(), serveDynamicApiPlugin()],
  publicDir: "public",
  build: {
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
    cssCodeSplit: false,
    assetsInlineLimit: 100000000,
  },
});

function getFolders(
  serverConfig: ViteDevServer["config"],
  subDir: string
): string[] {
  const targetDir = path.resolve(serverConfig.root, "public", subDir);
  // [!code focus]
  try {
    const dirents = fs.readdirSync(targetDir, { withFileTypes: true });
    return dirents
      .filter((dirent) => dirent.isDirectory())
      .map((dirent) => dirent.name);
  } catch (e: any) {
    console.error(`[DynamicAPI] Failed to read dir: ${targetDir}`, e.message);
    return [];
  }
}

function serveDynamicApiPlugin(): Plugin {
  return {
    name: "vite-plugin-serve-dynamic-api",

    configureServer(server: ViteDevServer) {
      server.middlewares.use(
        (req: IncomingMessage, res: ServerResponse, next: NextFunction) => {
          if (req.url === "/api/list-comics") {
            const bikaFolders = getFolders(server.config, "comics/bika");
            const jmFolders = getFolders(server.config, "comics/jm");

            const manifest = {
              bika: bikaFolders,
              jm: jmFolders,
            };

            console.log(JSON.stringify(manifest, null, 2));

            res.setHeader("Content-Type", "application/json");
            res.end(JSON.stringify(manifest));
            return;
          }

          if (req.url && req.url.startsWith("/comics/")) {
            try {
              const decodedUrl = decodeURIComponent(req.url.split("?")[0]);
              const filePath = path.resolve(
                server.config.root,
                "public",
                decodedUrl.slice(1)
              );

              console.log(`[Static File] Request: ${req.url}`);
              console.log(`[Static File] Decoded: ${decodedUrl}`);
              console.log(`[Static File] File path: ${filePath}`);
              console.log(`[Static File] Exists: ${fs.existsSync(filePath)}`);

              if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
                const ext = path.extname(filePath).toLowerCase();
                const contentTypes: Record<string, string> = {
                  ".json": "application/json",
                  ".jpg": "image/jpeg",
                  ".jpeg": "image/jpeg",
                  ".png": "image/png",
                  ".gif": "image/gif",
                  ".webp": "image/webp",
                };

                const contentType =
                  contentTypes[ext] || "application/octet-stream";
                res.setHeader("Content-Type", contentType);

                console.log(
                  `[Static File] Serving with Content-Type: ${contentType}`
                );

                const fileContent = fs.readFileSync(filePath);
                res.end(fileContent);
                return;
              } else {
                console.log(`[Static File] File not found or not a file`);
              }
            } catch (e) {
              console.error(`[Static File] Error serving ${req.url}:`, e);
            }
          }
          return next();
        }
      );
    },
  };
}
