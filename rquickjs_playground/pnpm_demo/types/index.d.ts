/**
 * Breeze 运行时类型声明统一入口。
 */

export * from "./bridge";
export * from "./crypto";
export * from "./fs";
export * from "./native";
export * from "./runtime";

// breeze-html 通过全局声明暴露，不额外导出具体类型。
export type {
  BreezeApi,
  BreezeDocument,
  BreezeHtmlStatic,
  BreezeSelection,
} from "./breeze-html";
