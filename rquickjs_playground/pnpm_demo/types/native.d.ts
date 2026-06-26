/**
 * Rust 原生 native API 类型声明。
 *
 * 对应运行时注入的 `native` 对象，用于高性能二进制处理。
 */

export type NativeChainStep = string | { op: string; extraInputId?: number };

export interface NativeApi {
  /** 是否支持二进制 bridge 传输。 */
  supportsBinaryBridge?: boolean;

  /** 将二进制数据放入 native 内存池，返回 id。 */
  put(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<number>;

  /** 根据 id 取出并释放 native 内存池中的数据。 */
  take(id: number): Promise<Uint8Array>;

  /** 释放指定 id 的 native 内存。 */
  free(id: number): Promise<void>;

  /** 执行单个 native 操作。 */
  exec(
    op: string,
    inputId: number,
    args?: unknown,
    extraInputId?: number | null,
  ): Promise<number>;

  /** 串行执行多个 native 操作。 */
  execChain(inputId: number, steps: NativeChainStep[]): Promise<number>;

  /** 一次性执行单个 native 操作并返回结果。 */
  run(
    op: string,
    input: Uint8Array,
    args?: unknown,
    extraInput?: Uint8Array | number,
  ): Promise<Uint8Array>;

  /** 串行执行多个 native 操作并返回结果。 */
  chain(
    steps: NativeChainStep[],
    input: Uint8Array | number,
  ): Promise<Uint8Array>;

  /** gzip 压缩。 */
  gzipCompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<Uint8Array>;

  /** gzip 解压。 */
  gzipDecompress(
    input: Uint8Array | ArrayBuffer | ArrayBufferView | number[],
  ): Promise<Uint8Array>;
}
