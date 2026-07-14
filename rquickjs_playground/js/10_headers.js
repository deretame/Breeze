(() => {
  const TOKEN_RE = /^[!#$%&'*+\-.^_`|~A-Za-z0-9]+$/;
  const HTTP_WS = /[\t\n\r ]/;

  const FORBIDDEN_REQUEST_HEADERS = new Set([
    "accept-charset",
    "accept-encoding",
    "access-control-request-headers",
    "access-control-request-method",
    "connection",
    "content-length",
    "cookie",
    "cookie2",
    "date",
    "dnt",
    "expect",
    "host",
    "keep-alive",
    "origin",
    "referer",
    "set-cookie",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade",
    "via",
  ]);

  const FORBIDDEN_METHODS = new Set(["trace", "track", "connect"]);
  const METHOD_OVERRIDE_HEADERS = new Set([
    "x-http-method",
    "x-http-method-override",
    "x-method-override",
  ]);

  const NO_CORS_SAFELISTED_NAMES = new Set([
    "accept",
    "accept-language",
    "content-language",
    "content-type",
  ]);
  const PRIVILEGED_NO_CORS_REQUEST_HEADERS = new Set([
    "cache-control",
    "content-language",
    "content-type",
    "expires",
    "last-modified",
    "pragma",
  ]);
  const NO_CORS_CONTENT_TYPES = new Set([
    "application/x-www-form-urlencoded",
    "multipart/form-data",
    "text/plain",
  ]);

  function isForbiddenRequestHeader(name, value) {
    const lower = name.toLowerCase();
    if (FORBIDDEN_REQUEST_HEADERS.has(lower)) return true;
    if (lower.startsWith("proxy-") || lower.startsWith("sec-")) return true;
    if (METHOD_OVERRIDE_HEADERS.has(lower)) {
      const tokens = value.split(",");
      for (let i = 0; i < tokens.length; i += 1) {
        const token = tokens[i]
          .replace(/^[\t\n\r ]+/, "")
          .replace(/[\t\n\r ]+$/, "")
          .toLowerCase();
        if (FORBIDDEN_METHODS.has(token)) return true;
      }
    }
    return false;
  }

  function isForbiddenResponseHeaderName(name) {
    const lower = name.toLowerCase();
    return lower === "set-cookie" || lower === "set-cookie2";
  }

  function isNoCorsContentType(value) {
    const match = String(value).match(/^([^;]+)/);
    if (!match) return false;
    const mime = match[1].replace(/[\t\n\r ]+/g, "").toLowerCase();
    return NO_CORS_CONTENT_TYPES.has(mime);
  }

  function isNoCorsSafelistedRequestHeader(name, value) {
    const lower = name.toLowerCase();
    if (!NO_CORS_SAFELISTED_NAMES.has(lower)) return false;
    if (["accept", "accept-language", "content-language"].includes(lower)) {
      if (value.length > 128) return false;
      return true;
    }
    // content-type
    if (value.length > 128) return false;
    return isNoCorsContentType(value);
  }

  function validateHeaderName(name) {
    const s = String(name);
    if (!TOKEN_RE.test(s)) {
      throw new TypeError("Invalid header name");
    }
    return s.toLowerCase();
  }

  function normalizeHeaderValue(value) {
    let s = String(value);
    // Strip leading/trailing HTTP whitespace and CR/LF (obs-fold at the edges).
    let start = 0;
    let end = s.length;
    while (start < end) {
      const c = s.charCodeAt(start);
      if (c === 0x09 || c === 0x0a || c === 0x0d || c === 0x20) {
        start += 1;
      } else {
        break;
      }
    }
    while (end > start) {
      const c = s.charCodeAt(end - 1);
      if (c === 0x09 || c === 0x0a || c === 0x0d || c === 0x20) {
        end -= 1;
      } else {
        break;
      }
    }
    return s.slice(start, end);
  }

  function validateHeaderValue(value) {
    const s = normalizeHeaderValue(value);
    for (let i = 0; i < s.length; i += 1) {
      const c = s.charCodeAt(i);
      if (c === 0x00 || c === 0x0a || c === 0x0d || c > 0xff) {
        throw new TypeError("Invalid header value");
      }
    }
    return s;
  }

  function sortAndCombine(list) {
    const groups = new Map();
    for (let i = 0; i < list.length; i += 1) {
      const [name, value] = list[i];
      if (name === "set-cookie") {
        let g = groups.get("set-cookie");
        if (!g) {
          g = { setCookie: true, entries: [] };
          groups.set("set-cookie", g);
        }
        g.entries.push([name, value]);
      } else {
        let g = groups.get(name);
        if (!g) {
          g = { setCookie: false, values: [] };
          groups.set(name, g);
        }
        g.values.push(value);
      }
    }
    const names = Array.from(groups.keys()).sort();
    const out = [];
    for (let i = 0; i < names.length; i += 1) {
      const g = groups.get(names[i]);
      if (g.setCookie) {
        for (let j = 0; j < g.entries.length; j += 1) {
          out.push(g.entries[j]);
        }
      } else {
        out.push([names[i], g.values.join(", ")]);
      }
    }
    return out;
  }

  const iteratorPrototype = Object.getPrototypeOf(Object.getPrototypeOf([][Symbol.iterator]()));
  const headersIteratorPrototype = Object.create(iteratorPrototype);
  headersIteratorPrototype.next = function next() {
    if (!this || typeof this._index !== "number") {
      throw new TypeError("next called on an object that is not a Headers iterator");
    }
    const list = sortAndCombine(this._headers._list);
    if (this._index >= list.length) {
      return { value: undefined, done: true };
    }
    const entry = list[this._index];
    this._index += 1;
    let value;
    if (this._kind === "key") {
      value = entry[0];
    } else if (this._kind === "value") {
      value = entry[1];
    } else {
      value = entry;
    }
    return { value, done: false };
  };
  headersIteratorPrototype[Symbol.iterator] = function () {
    return this;
  };

  function createIterator(headers, kind) {
    const iterator = Object.create(headersIteratorPrototype);
    iterator._headers = headers;
    iterator._kind = kind;
    iterator._index = 0;
    return iterator;
  }

  class Headers {
    constructor(init) {
      this._list = [];
      this._guard = "none";

      if (init === undefined) return;
      if (init === null) {
        throw new TypeError("Headers init must not be null");
      }
      if (typeof init !== "object") {
        throw new TypeError("Headers init must be an object");
      }

      if (typeof init[Symbol.iterator] === "function") {
        // Sequence path.
        for (const pair of init) {
          if (!Array.isArray(pair) || pair.length !== 2) {
            throw new TypeError("Headers sequence entry must be a [name, value] pair");
          }
          this.append(pair[0], pair[1]);
        }
        return;
      }

      // Record path (WebIDL record conversion).
      const keys = Reflect.ownKeys(init);
      for (let i = 0; i < keys.length; i += 1) {
        const key = keys[i];
        const descriptor = Object.getOwnPropertyDescriptor(init, key);
        if (!descriptor || descriptor.enumerable !== true) continue;
        const name = validateHeaderName(key);
        const value = validateHeaderValue(init[key]);
        this._list.push([name, value]);
      }
    }

    _checkGuard(name, value, forDelete) {
      if (this._guard === "immutable") {
        throw new TypeError("Headers guard is immutable");
      }
      if (this._guard === "response" && isForbiddenResponseHeaderName(name)) {
        return false;
      }
      if (this._guard === "request" && isForbiddenRequestHeader(name, value)) {
        return false;
      }
      if (this._guard === "request-no-cors") {
        if (forDelete) {
          if (!isNoCorsSafelistedRequestHeader(name, "") && !PRIVILEGED_NO_CORS_REQUEST_HEADERS.has(name.toLowerCase())) {
            return false;
          }
        } else {
          if (!isNoCorsSafelistedRequestHeader(name, value)) {
            return false;
          }
          const lower = name.toLowerCase();
          if (["accept", "accept-language", "content-language", "content-type"].includes(lower)) {
            if (value === "") {
              const existing = this._rawValues(lower);
              if (existing.length > 0) return false;
            }
            const existing = this._rawValues(lower);
            let combined;
            if (existing.length === 0) {
              combined = value;
            } else {
              combined = existing.join(", ") + ", " + value;
            }
            if (combined.length > 128) return false;
          }
        }
      }
      return true;
    }

    _rawValues(name) {
      const out = [];
      for (let i = 0; i < this._list.length; i += 1) {
        if (this._list[i][0] === name) out.push(this._list[i][1]);
      }
      return out;
    }

    append(name, value) {
      const key = validateHeaderName(name);
      const normValue = validateHeaderValue(value);
      if (!this._checkGuard(key, normValue, false)) return;
      this._list.push([key, normValue]);
    }

    delete(name) {
      const key = validateHeaderName(name);
      if (!this._checkGuard(key, "", true)) return;
      const next = [];
      for (let i = 0; i < this._list.length; i += 1) {
        if (this._list[i][0] !== key) next.push(this._list[i]);
      }
      this._list = next;
      if (this._guard === "request-no-cors") {
        this._removePrivilegedNoCorsHeaders();
      }
    }

    get(name) {
      const key = validateHeaderName(name);
      const values = this._rawValues(key);
      if (values.length === 0) return null;
      return values.join(", ");
    }

    getSetCookie() {
      return this._rawValues("set-cookie");
    }

    has(name) {
      const key = validateHeaderName(name);
      return this._rawValues(key).length > 0;
    }

    set(name, value) {
      const key = validateHeaderName(name);
      const normValue = validateHeaderValue(value);
      if (!this._checkGuard(key, normValue, false)) return;
      this.delete(key);
      this._list.push([key, normValue]);
    }

    forEach(callback, thisArg) {
      if (typeof callback !== "function") {
        throw new TypeError("Headers.forEach callback must be a function");
      }
      const iterator = this.entries();
      let entry = iterator.next();
      while (!entry.done) {
        callback.call(thisArg, entry.value[1], entry.value[0], this);
        entry = iterator.next();
      }
    }

    entries() {
      return createIterator(this, "key+value");
    }

    keys() {
      return createIterator(this, "key");
    }

    values() {
      return createIterator(this, "value");
    }

    [Symbol.iterator]() {
      return this.entries();
    }

    toObject() {
      const out = {};
      const list = sortAndCombine(this._list);
      for (let i = 0; i < list.length; i += 1) {
        const [name, value] = list[i];
        // Object keys cannot repeat; multiple set-cookie values collapse.
        out[name] = value;
      }
      return out;
    }

    _applyGuard(guard) {
      this._guard = guard;
      if (guard === "none" || guard === "immutable") return;
      const filtered = [];
      for (let i = 0; i < this._list.length; i += 1) {
        const [name, value] = this._list[i];
        if (guard === "response" && isForbiddenResponseHeaderName(name)) continue;
        if (guard === "request" && isForbiddenRequestHeader(name, value)) continue;
        if (guard === "request-no-cors") {
          if (!isNoCorsSafelistedRequestHeader(name, value)) continue;
        }
        filtered.push([name, value]);
      }
      this._list = filtered;
    }

    _removePrivilegedNoCorsHeaders() {
      const privileged = new Set([
        "cache-control",
        "content-language",
        "content-type",
        "expires",
        "last-modified",
        "pragma",
      ]);
      const next = [];
      for (let i = 0; i < this._list.length; i += 1) {
        if (!privileged.has(this._list[i][0])) next.push(this._list[i]);
      }
      this._list = next;
    }
  }

  globalThis.__web.Headers = Headers;
})();
