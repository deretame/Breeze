/**
 * BreezeHtml 类型声明 / Type declarations for BreezeHtml
 *
 * BreezeHtml 是 Breeze 插件运行时中注入的 Rust 原生 HTML 操作 API，
 * 实现了 cheerio 的一个子集，旨在以 cheerio 兼容的接口提供更高的解析性能。
 *
 * BreezeHtml is the Rust-backed, cheerio-compatible HTML manipulation API
 * injected into every Breeze plugin runtime. It implements a subset of cheerio
 * and is designed to offer higher parsing performance while keeping the API
 * familiar to cheerio users.
 *
 * 本项目并不意图完整替代 cheerio。如果现有 API 无法满足需求，插件仍可引入
 * 完整的 cheerio（或其它 HTML 解析库）进行处理。
 *
 * This project is not intended to be a full replacement for cheerio. If the
 * available API is insufficient for a particular task, plugins may still import
 * the full cheerio library (or any other HTML parsing library) as needed.
 *
 * 现有从 `"cheerio"` 导入的插件可以移除该依赖，改为直接使用
 * `const load = BreezeHtml.load;`。将此声明文件复制到插件项目并在全局类型
 * 声明中引用，TypeScript 即可识别 `BreezeHtml` 及其返回的选择器类型。
 *
 * Existing plugins that import from `"cheerio"` can drop that dependency and
 * use `const load = BreezeHtml.load;` directly. Copy this declaration file into
 * the plugin project and reference it from the global type declarations so
 * TypeScript knows about `BreezeHtml` and the returned selection types.
 */

export interface BreezeMappedResult<T> {
  readonly length: number;
  get(): T[];
}

export interface BreezeSelection {
  readonly length: number;

  find(selector: string): BreezeSelection;
  first(): BreezeSelection;
  last(): BreezeSelection;
  eq(index: number): BreezeSelection;
  closest(selector: string): BreezeSelection;
  parent(): BreezeSelection;
  children(selector?: string): BreezeSelection;
  siblings(selector?: string): BreezeSelection;
  next(selector?: string): BreezeSelection;
  prev(selector?: string): BreezeSelection;
  is(selector: string): boolean;

  filter(selector: string): BreezeSelection;
  filter(
    callback: (index: number, element: BreezeSelection) => boolean,
  ): BreezeSelection;
  has(selector: string): BreezeSelection;
  slice(start: number, end?: number): BreezeSelection;
  index(): number;

  attr(name: string): string | undefined;
  text(): string;
  html(): string | undefined;
  val(): string | undefined;

  toArray(): BreezeSelection[];
  each(callback: (index: number, element: BreezeSelection) => void): void;
  map<T>(
    callback: (index: number, element: BreezeSelection) => T,
  ): BreezeMappedResult<T>;
}

export interface BreezeDocument {
  select(selector: string): BreezeSelection;
}

export type BreezeApi = {
  (selector: string): BreezeSelection;
  (element: BreezeSelection): BreezeSelection;
};

export interface BreezeHtmlStatic {
  load(html: string): BreezeApi;
}

declare global {
  const BreezeHtml: BreezeHtmlStatic;
}

// Compatibility aliases for plugins that still reference cheerio type names.
export type CheerioAPI = BreezeApi;
export type Cheerio<T = any> = BreezeSelection;
