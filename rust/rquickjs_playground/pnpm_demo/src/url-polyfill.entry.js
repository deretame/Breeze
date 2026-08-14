import URLCtor from "core-js-pure/actual/url";
import URLSearchParamsCtor from "core-js-pure/actual/url-search-params";

(() => {
  const URL = URLCtor;
  const URLSearchParams = URLSearchParamsCtor;

  if (typeof URL !== "function" || typeof URLSearchParams !== "function") {
    throw new TypeError("core-js-pure URL polyfill not available");
  }

  if (!globalThis.__web || typeof globalThis.__web !== "object") {
    globalThis.__web = {};
  }

  globalThis.__web.URL = URL;
  globalThis.__web.URLSearchParams = URLSearchParams;

  globalThis.URL = URL;
  globalThis.URLSearchParams = URLSearchParams;
})();
