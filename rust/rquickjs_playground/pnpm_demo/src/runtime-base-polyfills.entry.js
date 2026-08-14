import { TextEncoder as FTTextEncoder, TextDecoder as FTTextDecoder } from "fast-text-encoding";
import * as ababModule from "abab";
import { Buffer as PolyfillBuffer } from "buffer";
import * as blobPolyfill from "blob-polyfill";
import "formdata-polyfill/FormData.js";

(() => {
  const TextEncoder = globalThis.TextEncoder || FTTextEncoder;
  const TextDecoder = globalThis.TextDecoder || FTTextDecoder;
  const ababAtob =
    (typeof ababModule.atob === "function" && ababModule.atob) ||
    (ababModule.default &&
      typeof ababModule.default.atob === "function" &&
      ababModule.default.atob) ||
    null;
  const ababBtoa =
    (typeof ababModule.btoa === "function" && ababModule.btoa) ||
    (ababModule.default &&
      typeof ababModule.default.btoa === "function" &&
      ababModule.default.btoa) ||
    null;
  if (typeof TextEncoder !== "function" || typeof TextDecoder !== "function") {
    throw new TypeError("text-encoding polyfill not available");
  }

  if (!globalThis.__web || typeof globalThis.__web !== "object") {
    globalThis.__web = {};
  }

  globalThis.__web.TextEncoder = TextEncoder;
  globalThis.__web.TextDecoder = TextDecoder;

  globalThis.TextEncoder = TextEncoder;
  globalThis.TextDecoder = TextDecoder;
  if (typeof globalThis.Buffer !== "function") {
    globalThis.Buffer = PolyfillBuffer;
  }
  if (typeof globalThis.Blob !== "function" && typeof blobPolyfill.Blob === "function") {
    globalThis.Blob = blobPolyfill.Blob;
  }
  if (typeof globalThis.File !== "function" && typeof blobPolyfill.File === "function") {
    globalThis.File = blobPolyfill.File;
  }
  if (typeof globalThis.Blob !== "function") {
    throw new TypeError("Blob polyfill not available");
  }
  if (typeof globalThis.File !== "function") {
    globalThis.File = class File extends globalThis.Blob {
      constructor(parts = [], name = "", options = {}) {
        super(parts, options);
        this.name = String(name);
        const lm = options && options.lastModified;
        const ts = Number(lm);
        this.lastModified = Number.isFinite(ts) ? ts : Date.now();
      }
    };
  }
  class FormDataFallback {
    constructor() {
      this._entries = [];
    }
    append(name, value, filename) {
      const key = String(name);
      if (value instanceof globalThis.Blob) {
        let fileValue = value;
        if (typeof filename === "string" && typeof globalThis.File === "function") {
          fileValue = new globalThis.File([value], filename, { type: value.type || "" });
        }
        this._entries.push([key, fileValue]);
        return;
      }
      this._entries.push([key, String(value)]);
    }
    set(name, value, filename) {
      this.delete(name);
      this.append(name, value, filename);
    }
    get(name) {
      const key = String(name);
      for (const [n, v] of this._entries) {
        if (n === key) return v;
      }
      return null;
    }
    getAll(name) {
      const key = String(name);
      return this._entries.filter(([n]) => n === key).map(([, v]) => v);
    }
    has(name) {
      const key = String(name);
      return this._entries.some(([n]) => n === key);
    }
    delete(name) {
      const key = String(name);
      this._entries = this._entries.filter(([n]) => n !== key);
    }
    *entries() {
      for (const entry of this._entries) yield entry;
    }
    *keys() {
      for (const [name] of this._entries) yield name;
    }
    *values() {
      for (const [, value] of this._entries) yield value;
    }
    forEach(callback, thisArg) {
      for (const [name, value] of this._entries) {
        callback.call(thisArg, value, name, this);
      }
    }
    [Symbol.iterator]() {
      return this.entries();
    }
  }
  globalThis.FormData = FormDataFallback;

  if (typeof globalThis.atob !== "function" && typeof ababAtob === "function") {
    globalThis.atob = ababAtob;
  }
  if (typeof globalThis.btoa !== "function" && typeof ababBtoa === "function") {
    globalThis.btoa = ababBtoa;
  }

  globalThis.__web.atob = globalThis.atob;
  globalThis.__web.btoa = globalThis.btoa;
  globalThis.__web.Buffer = globalThis.Buffer;
  globalThis.__web.Blob = globalThis.Blob;
  globalThis.__web.File = globalThis.File;
  globalThis.__web.FormData = globalThis.FormData;
})();
