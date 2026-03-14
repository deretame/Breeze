import type { Configuration } from "@rspack/core";

export type CreateRspackConfigOptions = {
  rootDir: string;
  outPath: string;
  outFileName: string;
};

export function createRspackConfig({
  rootDir,
  outPath,
  outFileName,
}: CreateRspackConfigOptions): Configuration {
  return {
    mode: "production",
    entry: `${rootDir}/src/index.ts`,
    target: "web",
    devtool: false,
    module: {
      rules: [
        {
          test: /\.tsx?$/,
          exclude: /node_modules/,
          loader: "builtin:swc-loader",
          options: {
            jsc: {
              parser: {
                syntax: "typescript",
                tsx: true,
              },
              target: "es2019",
            },
          },
        },
      ],
    },
    resolve: {
      extensions: [".ts", ".tsx", ".mjs", ".js", ".json"],
    },
    output: {
      path: outPath,
      filename: outFileName,
      library: {
        type: "commonjs2",
      },
    },
    optimization: {
      minimize: true,
      usedExports: true,
      sideEffects: true,
      concatenateModules: true,
    },
  };
}
