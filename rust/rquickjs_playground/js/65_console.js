(() => {
  function safeStringify(value) {
    if (typeof value === "string") return value;
    if (value instanceof Error) {
      return `${value.name || "Error"}: ${value.message || ""}${value.stack ? `\n${value.stack}` : ""}`;
    }
    if (value === null) return "null";
    if (value === undefined) return "undefined";
    if (typeof value === "bigint") return `${value}n`;
    if (typeof value === "function") return `[Function ${value.name || "anonymous"}]`;

    try {
      const seen = new WeakSet();
      return JSON.stringify(value, (_key, v) => {
        if (typeof v === "bigint") return `${v}n`;
        if (v && typeof v === "object") {
          if (seen.has(v)) return "[Circular]";
          seen.add(v);
        }
        return v;
      });
    } catch (_err) {
      try {
        return String(value);
      } catch (_err2) {
        return "[Unserializable]";
      }
    }
  }

  function emit(level, args) {
    const message = Array.from(args || []).map((a) => safeStringify(a)).join(" ");
    try {
      if (typeof globalThis.__log_emit === "function") {
        globalThis.__log_emit(String(level || "log"), message);
      }
    } catch (_err) {
    }
  }

  const consoleObj = {
    log(...args) {
      emit("log", args);
    },
    info(...args) {
      emit("info", args);
    },
    debug(...args) {
      emit("debug", args);
    },
    warn(...args) {
      emit("warn", args);
    },
    error(...args) {
      emit("error", args);
    },
    dir(value) {
      emit("log", [value]);
    },
    assert(condition, ...args) {
      if (condition) return;
      const prefix = "Assertion failed";
      if (args.length === 0) emit("error", [prefix]);
      else emit("error", [prefix, ...args]);
    },
  };

  globalThis.console = consoleObj;
  globalThis.__web.console = consoleObj;
})();
