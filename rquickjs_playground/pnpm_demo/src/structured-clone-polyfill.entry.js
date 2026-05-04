import "core-js/actual/structured-clone";

(() => {
  const sc = globalThis.structuredClone;
  if (typeof sc !== "function") {
    throw new TypeError("core-js structuredClone polyfill not available");
  }
  if (!globalThis.__web || typeof globalThis.__web !== "object") {
    globalThis.__web = {};
  }
  globalThis.__web.structuredClone = sc;
})();
