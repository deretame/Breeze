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

    static abort(reason) {
      const controller = new AbortController();
      controller.abort(reason);
      return controller.signal;
    }

    static timeout(ms) {
      const delay = Number(ms);
      const timeoutMs = Number.isFinite(delay) && delay >= 0 ? Math.floor(delay) : 0;
      const controller = new AbortController();
      setTimeout(() => {
        const err = new Error(`signal timed out (${timeoutMs}ms)`);
        err.name = "TimeoutError";
        controller.abort(err);
      }, timeoutMs);
      return controller.signal;
    }

    static any(signals) {
      if (!signals || typeof signals[Symbol.iterator] !== "function") {
        throw new TypeError("AbortSignal.any 参数必须是可迭代对象");
      }

      const controller = new AbortController();
      const list = Array.from(signals);
      if (list.length === 0) return controller.signal;

      const cleanup = [];
      const abortFrom = (source) => {
        if (controller.signal.aborted) return;
        controller.abort(source ? source.reason : undefined);
        for (const fn of cleanup) fn();
      };

      for (const signal of list) {
        if (!signal || typeof signal.addEventListener !== "function" || typeof signal.removeEventListener !== "function") {
          throw new TypeError("AbortSignal.any 参数元素必须是 AbortSignal");
        }
        if (signal.aborted) {
          abortFrom(signal);
          return controller.signal;
        }
      }

      for (const signal of list) {
        const listener = () => abortFrom(signal);
        signal.addEventListener("abort", listener);
        cleanup.push(() => signal.removeEventListener("abort", listener));
      }
      return controller.signal;
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
