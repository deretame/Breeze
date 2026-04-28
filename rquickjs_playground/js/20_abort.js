(() => {
  class AbortSignal {
    constructor() {
      this.aborted = false;
      this.reason = undefined;
      this.onabort = null;
      this._listeners = [];
    }

    addEventListener(type, listener) {
      if (type === "abort" && typeof listener === "function") {
        this._listeners.push(listener);
      }
    }

    removeEventListener(type, listener) {
      if (type !== "abort") return;
      this._listeners = this._listeners.filter((it) => it !== listener);
    }

    _dispatchAbort() {
      const evt = { type: "abort", target: this };
      if (typeof this.onabort === "function") this.onabort(evt);
      for (const listener of this._listeners) listener.call(this, evt);
    }

    throwIfAborted() {
      if (!this.aborted) return;
      const err = new Error(this.reason || "请求已取消");
      err.name = "AbortError";
      throw err;
    }
  }

  class AbortController {
    constructor() {
      this.signal = new AbortSignal();
    }

    abort(reason) {
      if (this.signal.aborted) return;
      this.signal.aborted = true;
      this.signal.reason = reason;
      this.signal._dispatchAbort();
    }
  }

  globalThis.__web.AbortController = AbortController;
  globalThis.__web.AbortSignal = AbortSignal;
})();
