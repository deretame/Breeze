(() => {
  const { normalizeHeaderName } = globalThis.__web;

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
      if (this._map.has(key)) {
        this._map.set(key, this._map.get(key) + ", " + nextValue);
      } else {
        this._map.set(key, nextValue);
      }
    }

    set(name, value) {
      this._map.set(normalizeHeaderName(name), String(value));
    }

    get(name) {
      const value = this._map.get(normalizeHeaderName(name));
      return value === undefined ? null : value;
    }

    has(name) {
      return this._map.has(normalizeHeaderName(name));
    }

    delete(name) {
      this._map.delete(normalizeHeaderName(name));
    }

    forEach(callback, thisArg) {
      for (const [key, value] of this._map.entries()) {
        callback.call(thisArg, value, key, this);
      }
    }

    entries() {
      return this._map.entries();
    }

    keys() {
      return this._map.keys();
    }

    values() {
      return this._map.values();
    }

    [Symbol.iterator]() {
      return this.entries();
    }

    toObject() {
      const out = {};
      this.forEach((value, key) => {
        out[key] = value;
      });
      return out;
    }
  }

  globalThis.__web.Headers = Headers;
})();
