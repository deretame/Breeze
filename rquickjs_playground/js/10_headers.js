(() => {
  const { normalizeHeaderName } = globalThis.__web;
  const rewriteFn = globalThis.__headers_rewrite;
  const queryFn = globalThis.__headers_query;

  function snapshotJson(map) {
    const out = {};
    for (const [k, v] of map.entries()) out[k] = v;
    return JSON.stringify(out);
  }

  function applyJsonToMap(map, headersJson) {
    map.clear();
    let obj = {};
    try {
      const parsed = JSON.parse(String(headersJson || "{}"));
      if (parsed && typeof parsed === "object") obj = parsed;
    } catch (_err) {}
    for (const key of Object.keys(obj)) {
      map.set(normalizeHeaderName(key), String(obj[key]));
    }
  }

  function callRewrite(map, op, name, value) {
    if (typeof rewriteFn !== "function") return false;
    try {
      const next = rewriteFn(op, snapshotJson(map), name, value);
      applyJsonToMap(map, next);
      return true;
    } catch (_err) {
      return false;
    }
  }

  function callQuery(map, op, name) {
    if (typeof queryFn !== "function") return null;
    try {
      const raw = queryFn(op, snapshotJson(map), name);
      const payload = JSON.parse(String(raw || "{}"));
      if (!payload || payload.ok !== true) return null;
      return payload.data;
    } catch (_err) {
      return null;
    }
  }

  class Headers {
    constructor(init) {
      this._map = new Map();
      if (!init) return;

      if (init instanceof Headers) {
        init.forEach((value, key) => this.append(key, value));
        return;
      }

      if (Array.isArray(init)) {
        for (const pair of init) {
          if (!Array.isArray(pair) || pair.length !== 2) {
            throw new TypeError("Headers 初始化项必须是 [key, value]");
          }
          this.append(pair[0], pair[1]);
        }
        return;
      }

      if (typeof init === "object") {
        for (const key of Object.keys(init)) {
          this.append(key, init[key]);
        }
      }
    }

    append(name, value) {
      const key = normalizeHeaderName(name);
      const nextValue = String(value);
      if (callRewrite(this._map, "append", key, nextValue)) return;
      if (this._map.has(key)) {
        this._map.set(key, this._map.get(key) + ", " + nextValue);
      } else {
        this._map.set(key, nextValue);
      }
    }

    set(name, value) {
      const key = normalizeHeaderName(name);
      const nextValue = String(value);
      if (callRewrite(this._map, "set", key, nextValue)) return;
      this._map.set(key, nextValue);
    }

    get(name) {
      const key = normalizeHeaderName(name);
      const fromRust = callQuery(this._map, "get", key);
      if (fromRust !== null) {
        return fromRust === undefined || fromRust === null ? null : String(fromRust);
      }
      const value = this._map.get(key);
      return value === undefined ? null : value;
    }

    has(name) {
      const key = normalizeHeaderName(name);
      const fromRust = callQuery(this._map, "has", key);
      if (fromRust !== null) return fromRust === true;
      return this._map.has(key);
    }

    delete(name) {
      const key = normalizeHeaderName(name);
      if (callRewrite(this._map, "delete", key, null)) return;
      this._map.delete(key);
    }

    forEach(callback, thisArg) {
      const entries = this.entries();
      for (const [key, value] of entries) {
        callback.call(thisArg, value, key, this);
      }
    }

    entries() {
      const fromRust = callQuery(this._map, "entries", null);
      if (Array.isArray(fromRust)) {
        const list = fromRust.map((pair) => [String(pair[0]), String(pair[1])]);
        return list[Symbol.iterator]();
      }
      return this._map.entries();
    }

    keys() {
      return Array.from(this.entries(), ([k]) => k)[Symbol.iterator]();
    }

    values() {
      return Array.from(this.entries(), ([, v]) => v)[Symbol.iterator]();
    }

    [Symbol.iterator]() {
      return this.entries();
    }

    toObject() {
      const out = {};
      for (const [key, value] of this.entries()) {
        out[key] = value;
      }
      return out;
    }
  }

  globalThis.__web.Headers = Headers;
})();
