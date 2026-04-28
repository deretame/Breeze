(() => {
  const EVENTED_WASI_PENDING = new Map();

  function parseHost(raw) {
    const payload = JSON.parse(raw);
    if (!payload.ok) {
      throw new Error(payload.error || "wasi 调用失败");
    }
    return payload;
  }

  globalThis.__host_runtime_wasi_complete = function __host_runtime_wasi_complete(requestId, payloadRaw) {
    const pending = EVENTED_WASI_PENDING.get(Number(requestId));
    if (!pending) return;
    EVENTED_WASI_PENDING.delete(Number(requestId));

    const { resolve, reject } = pending;
    try {
      const res = parseHost(String(payloadRaw || "{}"));
      resolve({
        exitCode: Number(res.exitCode || 0),
        stdoutId: Number(res.stdoutId),
        stderrId: Number(res.stderrId),
      });
    } catch (err) {
      reject(err);
    }
  };

  async function runById(moduleId, options = {}) {
    const stdinId = options.stdinId === undefined || options.stdinId === null
      ? null
      : Number(options.stdinId);
    const argsJson = options.args === undefined ? null : JSON.stringify(options.args);
    const consumeModule = options.reuseModule ? false : true;
    return new Promise((resolve, reject) => {
      let requestId = null;

      try {
        const started = parseHost(
          globalThis.__wasi_run_start_evented(Number(moduleId), stdinId, argsJson, consumeModule),
        );
        requestId = Number(started.id);
        EVENTED_WASI_PENDING.set(requestId, { resolve, reject });
      } catch (err) {
        if (requestId !== null) {
          try {
            globalThis.__wasi_run_drop_evented(requestId);
          } catch (_dropErr) {
          }
        }
        reject(err);
      }
    });
  }

  async function run(moduleBytes, options = {}) {
    const moduleId = await globalThis.native.put(moduleBytes);
    return runById(moduleId, options);
  }

  async function takeStdout(result) {
    return globalThis.native.take(result.stdoutId);
  }

  async function takeStderr(result) {
    return globalThis.native.take(result.stderrId);
  }

  globalThis.__web.wasi = {
    run,
    runById,
    takeStdout,
    takeStderr,
  };
})();
