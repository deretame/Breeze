/**
 * 文件系统与路径 API 类型声明。
 *
 * 对应运行时注入的 `fs`、`path` 对象。
 */

export interface FsDirent {
  name: string;
  isFile(): boolean;
  isDirectory(): boolean;
}

export interface FsStats {
  size: number;
  isFile(): boolean;
  isDirectory(): boolean;
}

export interface FsApi {
  promises: {
    readFile(
      path: string,
      encoding?: string | null,
    ): Promise<Uint8Array | string>;
    writeFile(
      path: string,
      data: string | ArrayBuffer | ArrayBufferView | Uint8Array,
    ): Promise<void>;
    appendFile(
      path: string,
      data: string | ArrayBuffer | ArrayBufferView | Uint8Array,
    ): Promise<void>;
    mkdir(path: string, options?: { recursive?: boolean }): Promise<void>;
    readdir(
      path: string,
      options?: { withFileTypes?: boolean },
    ): Promise<(string | FsDirent)[]>;
    stat(path: string): Promise<FsStats>;
    rm(
      path: string,
      options?: { recursive?: boolean; force?: boolean },
    ): Promise<void>;
  };
}

export interface PathApi {
  sep: string;
  delimiter: string;
  normalize(path: string): string;
  isAbsolute(path: string): boolean;
  join(...parts: string[]): string;
  resolve(...parts: string[]): string;
  dirname(path: string): string;
  basename(path: string, suffix?: string): string;
  extname(path: string): string;
}
